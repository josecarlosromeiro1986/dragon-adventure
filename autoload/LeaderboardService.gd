extends Node

## Cliente do Ranking Global Online (Supabase REST + Publishable Key) e fallback local offline.

signal rankings_loaded(category: String, entries: Array, from_network: bool, error_msg: String)
signal submission_finished(success: bool, entry: Dictionary, error_msg: String)

const SUPABASE_URL := "https://tgwoptupssqptvpmuija.supabase.co"
const SUPABASE_PUBLISHABLE_KEY := "sb_publishable_r5Ammd2iO2rOE5eFn8mGaw_Hpo_wThb"
const TABLE_NAME := "speedrun_ranks"
const LOCAL_RANKS_PATH := "user://speedrun_ranks.json"
const MIN_GLOBAL_TIME_SECONDS: float = 10.0
const MAX_LOCAL_RECORDS: int = 100

var last_player_name: String = ""
var local_records: Array = []
var _remote_cache: Dictionary = {
	"manual": [],
	"auto_hunt": []
}
var _remote_loaded: Dictionary = {
	"manual": false,
	"auto_hunt": false
}
var _active_fetch_req: Dictionary = {}
var _active_submit_req: HTTPRequest = null
var _js_bridge_ready: bool = false
var _next_js_req_id: int = 1
var _pending_js_reqs: Dictionary = {}

func _ready():
	_load_local_data()

static func normalize_category(category: String) -> String:
	return "auto_hunt" if category == "auto_hunt" else "manual"

static func format_category_name(category: String) -> String:
	return "Com Auto-Hunt" if normalize_category(category) == "auto_hunt" else "Sem Auto-Hunt (Manual)"

static func format_hud_time(seconds: float) -> String:
	var total := maxi(0, int(floor(seconds)))
	var hrs := total / 3600
	var mins := (total % 3600) / 60
	var secs := total % 60
	if hrs > 0:
		return "%d:%02d:%02d" % [hrs, mins, secs]
	return "%02d:%02d" % [mins, secs]

static func format_exact_time(seconds: float) -> String:
	var clamped := maxf(0.0, seconds)
	var total_cs := int(round(clamped * 100.0))
	var cs := total_cs % 100
	var total_sec := total_cs / 100
	var hrs := total_sec / 3600
	var mins := (total_sec % 3600) / 60
	var secs := total_sec % 60
	if hrs > 0:
		return "%d:%02d:%02d.%02d" % [hrs, mins, secs, cs]
	return "%02d:%02d.%02d" % [mins, secs, cs]

static func format_date_short(iso_str: String) -> String:
	var cleaned := iso_str.strip_edges()
	if cleaned.length() >= 10 and cleaned[4] == "-" and cleaned[7] == "-":
		var yy := cleaned.substr(2, 2)
		var mm := cleaned.substr(5, 2)
		var dd := cleaned.substr(8, 2)
		return "%s/%s/%s" % [dd, mm, yy]
	return "--/--/--"

static func sanitize_player_name(raw_name: String) -> String:
	var out := ""
	var prev_space := false
	for i in range(raw_name.length()):
		var code := raw_name.unicode_at(i)
		if code < 32 or code == 127 or code == 60 or code == 62:
			continue
		var ch := raw_name.substr(i, 1)
		if ch == " " or ch == "\t":
			if not prev_space and out != "":
				out += " "
			prev_space = true
		else:
			out += ch
			prev_space = false
	return out.strip_edges()

static func validate_player_name(raw_name: String) -> String:
	var cleaned := sanitize_player_name(raw_name)
	if cleaned.length() < 2:
		return "Informe um apelido com pelo menos 2 caracteres."
	if cleaned.length() > 20:
		return "O apelido deve ter no máximo 20 caracteres."
	return ""

func _make_headers(extra: Array = []) -> PackedStringArray:
	var headers := PackedStringArray([
		"apikey: " + SUPABASE_PUBLISHABLE_KEY,
		"Accept: application/json"
	])
	for h in extra:
		headers.append(str(h))
	return headers

func _load_local_data():
	if not FileAccess.file_exists(LOCAL_RANKS_PATH):
		return
	var f := FileAccess.open(LOCAL_RANKS_PATH, FileAccess.READ)
	if not f:
		return
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var d: Dictionary = json.data
		last_player_name = sanitize_player_name(str(d.get("player_name", "")))
		local_records.clear()
		if d.has("local_records") and d["local_records"] is Array:
			for item in d["local_records"]:
				if item is Dictionary:
					local_records.append(_normalize_entry(item, true))
		_sort_entries(local_records)

func _save_local_data():
	var payload := {
		"player_name": last_player_name,
		"local_records": local_records
	}
	var f := FileAccess.open(LOCAL_RANKS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()

func _normalize_entry(raw: Dictionary, default_local: bool = false) -> Dictionary:
	return {
		"run_uid": str(raw.get("run_uid", "")),
		"player_name": sanitize_player_name(str(raw.get("player_name", "Herói"))),
		"category": normalize_category(str(raw.get("category", "manual"))),
		"time_seconds": snappedf(maxf(0.0, float(raw.get("time_seconds", 0.0))), 0.01),
		"level": clampi(int(raw.get("level", 1)), 1, 999),
		"total_kills": maxi(0, int(raw.get("total_kills", 0))),
		"bosses_defeated": clampi(int(raw.get("bosses_defeated", 6)), 1, 6),
		"game_version": str(raw.get("game_version", GameData.get_game_version())),
		"created_at": str(raw.get("created_at", "")),
		"synced": bool(raw.get("synced", not default_local)),
		"is_local": default_local or _has_local_run(str(raw.get("run_uid", "")))
	}

func _has_local_run(run_uid: String) -> bool:
	if run_uid == "":
		return false
	for rec in local_records:
		if str(rec.get("run_uid", "")) == run_uid:
			return true
	return false

func _sort_entries(arr: Array):
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ta := float(a.get("time_seconds", 9999999.0))
		var tb := float(b.get("time_seconds", 9999999.0))
		if not is_equal_approx(ta, tb):
			return ta < tb
		return str(a.get("created_at", "")) < str(b.get("created_at", ""))
	)

func get_local_records(category: String) -> Array:
	var cat := normalize_category(category)
	var out: Array = []
	for rec in local_records:
		if normalize_category(str(rec.get("category", "manual"))) == cat:
			out.append(rec.duplicate(true))
	_sort_entries(out)
	return out

func get_cached_global_records(category: String) -> Array:
	var cat := normalize_category(category)
	if _remote_loaded.get(cat, false):
		return _merge_with_local(cat, _remote_cache.get(cat, []))
	return get_local_records(cat)

func _merge_with_local(category: String, remote_list: Array) -> Array:
	var seen_uids: Dictionary = {}
	var merged: Array = []
	for item in remote_list:
		var norm := _normalize_entry(item, false)
		var uid := str(norm.get("run_uid", ""))
		if uid != "":
			seen_uids[uid] = true
		norm["is_local"] = _has_local_run(uid)
		merged.append(norm)
	for rec in get_local_records(category):
		var uid := str(rec.get("run_uid", ""))
		if uid == "" or not seen_uids.has(uid):
			if not bool(rec.get("synced", false)):
				merged.append(rec)
	_sort_entries(merged)
	return merged

func is_run_synced(run_uid: String) -> bool:
	for rec in local_records:
		if str(rec.get("run_uid", "")) == run_uid:
			return bool(rec.get("synced", false))
	return false

func get_personal_best(category: String, excluding_run_uid: String = "") -> float:
	var cat := normalize_category(category)
	var best := -1.0
	for rec in local_records:
		if normalize_category(str(rec.get("category", "manual"))) != cat:
			continue
		if excluding_run_uid != "" and str(rec.get("run_uid", "")) == excluding_run_uid:
			continue
		var t := float(rec.get("time_seconds", 0.0))
		if t > 0.0 and (best < 0.0 or t < best):
			best = t
	return best

func is_personal_best(category: String, time_sec: float, excluding_run_uid: String = "") -> bool:
	var prev_best := get_personal_best(category, excluding_run_uid)
	return prev_best < 0.0 or time_sec < prev_best

func _now_iso_utc() -> String:
	var dt := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		int(dt.get("year", 2026)),
		int(dt.get("month", 1)),
		int(dt.get("day", 1)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
		int(dt.get("second", 0))
	]

func build_current_run_entry(player_name: String) -> Dictionary:
	var uid := GameState.ensure_run_uid()
	var cleaned_name := sanitize_player_name(player_name)
	return {
		"run_uid": uid,
		"player_name": cleaned_name,
		"category": GameState.get_run_category(),
		"time_seconds": snappedf(maxf(0.01, GameState.play_time_seconds), 0.01),
		"level": clampi(GameState.level, 1, 999),
		"total_kills": maxi(0, GameState.total_kills_all_time),
		"bosses_defeated": clampi(GameState.get_defeated_boss_count(), 1, 6),
		"game_version": GameData.get_game_version(),
		"created_at": _now_iso_utc(),
		"synced": is_run_synced(uid),
		"is_local": true
	}

func record_local_run(player_name: String) -> Dictionary:
	var cleaned := sanitize_player_name(player_name)
	if cleaned.length() >= 2:
		last_player_name = cleaned
	elif last_player_name.length() >= 2:
		cleaned = last_player_name
	else:
		cleaned = "Daniel Ragnar"

	var entry := build_current_run_entry(cleaned)
	var uid := str(entry["run_uid"])
	var found := false
	for i in range(local_records.size()):
		if str(local_records[i].get("run_uid", "")) == uid:
			var was_synced := bool(local_records[i].get("synced", false))
			entry["synced"] = was_synced
			local_records[i] = entry
			found = true
			break
	if not found:
		local_records.append(entry)
	_sort_entries(local_records)
	if local_records.size() > MAX_LOCAL_RECORDS:
		local_records.resize(MAX_LOCAL_RECORDS)
	_save_local_data()
	return entry

func _mark_run_synced(run_uid: String, remote_row: Dictionary = {}):
	for i in range(local_records.size()):
		if str(local_records[i].get("run_uid", "")) == run_uid:
			local_records[i]["synced"] = true
			if remote_row.has("created_at"):
				local_records[i]["created_at"] = str(remote_row["created_at"])
			break
	_save_local_data()

func _ensure_js_bridge():
	if _js_bridge_ready or not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
	if (!window.__daSupabaseReq) {
		window.__daSupabaseReq = function(url, method, headersJson, bodyText, onOk, onErr) {
			try {
				var hdrs = JSON.parse(headersJson || "{}");
				var opts = { method: method || "GET", headers: hdrs, mode: "cors", credentials: "omit" };
				if (bodyText !== "" && method !== "GET" && method !== "HEAD") {
					opts.body = bodyText;
				}
				fetch(url, opts).then(function(res) {
					return res.text().then(function(txt) {
						onOk(res.status, txt);
					});
				}).catch(function(err) {
					onErr(String(err || "Network error"));
				});
			} catch (e) {
				onErr(String(e || "JS fetch error"));
			}
		};
	}
	""", true)
	_js_bridge_ready = true

func _web_fetch_async(url: String, method: String, headers_dict: Dictionary, body_text: String, on_done: Callable):
	_ensure_js_bridge()
	var win := JavaScriptBridge.get_interface("window")
	if win == null:
		on_done.call(false, 0, "", "Ponte WebGL indisponível")
		return

	var req_id := _next_js_req_id
	_next_js_req_id += 1
	var done_flag := [false]

	var cb_ok := JavaScriptBridge.create_callback(func(args: Array):
		if done_flag[0]:
			return
		done_flag[0] = true
		_pending_js_reqs.erase(req_id)
		var status := int(args[0]) if args.size() > 0 else 0
		var text := str(args[1]) if args.size() > 1 else ""
		on_done.call(true, status, text, "")
	)
	var cb_err := JavaScriptBridge.create_callback(func(args: Array):
		if done_flag[0]:
			return
		done_flag[0] = true
		_pending_js_reqs.erase(req_id)
		var err_str := str(args[0]) if args.size() > 0 else "erro de rede"
		on_done.call(false, 0, "", err_str)
	)
	_pending_js_reqs[req_id] = [cb_ok, cb_err]

	get_tree().create_timer(10.0, true).timeout.connect(func():
		if done_flag[0]:
			return
		done_flag[0] = true
		_pending_js_reqs.erase(req_id)
		on_done.call(false, 0, "", "tempo esgotado")
	)

	win.__daSupabaseReq(url, method, JSON.stringify(headers_dict), body_text, cb_ok, cb_err)

func fetch_global_rankings(category: String, limit: int = 50):
	var cat := normalize_category(category)
	var url := "%s/rest/v1/%s?select=id,run_uid,player_name,category,time_seconds,level,total_kills,bosses_defeated,game_version,created_at&category=eq.%s&order=time_seconds.asc,created_at.asc&limit=%d" % [
		SUPABASE_URL,
		TABLE_NAME,
		cat,
		clampi(limit, 1, 100)
	]

	if OS.has_feature("web"):
		var web_headers := {
			"apikey": SUPABASE_PUBLISHABLE_KEY,
			"Accept": "application/json"
		}
		_web_fetch_async(url, "GET", web_headers, "", func(ok: bool, status: int, body_txt: String, err_msg: String):
			if not ok or status < 200 or status >= 300:
				var fallback := get_cached_global_records(cat)
				var msg := err_msg if not ok else _describe_http_status(status, body_txt)
				rankings_loaded.emit(cat, fallback, false, msg)
				return
			_handle_fetch_json(cat, body_txt)
		)
		return

	var prev_req: HTTPRequest = _active_fetch_req.get(cat)
	if is_instance_valid(prev_req):
		prev_req.cancel_request()
		prev_req.queue_free()

	var req := HTTPRequest.new()
	req.use_threads = false
	req.accept_gzip = false
	req.timeout = 10.0
	add_child(req)
	_active_fetch_req[cat] = req

	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if is_instance_valid(req):
			req.queue_free()
		if _active_fetch_req.get(cat) == req:
			_active_fetch_req.erase(cat)

		if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
			var fallback := get_cached_global_records(cat)
			var msg := _describe_http_error(result, response_code, body)
			rankings_loaded.emit(cat, fallback, false, msg)
			return

		_handle_fetch_json(cat, body.get_string_from_utf8())
	)

	var err := req.request(url, _make_headers(), HTTPClient.METHOD_GET)
	if err != OK:
		if is_instance_valid(req):
			req.queue_free()
		_active_fetch_req.erase(cat)
		rankings_loaded.emit(cat, get_cached_global_records(cat), false, "Não foi possível iniciar a conexão com o ranking.")

func _handle_fetch_json(cat: String, text: String):
	var parsed = JSON.parse_string(text)
	if not (parsed is Array):
		var fallback := get_cached_global_records(cat)
		rankings_loaded.emit(cat, fallback, false, "Resposta inesperada do servidor de ranking.")
		return

	var entries: Array = []
	var local_dirty := false
	for row in parsed:
		if row is Dictionary:
			var norm := _normalize_entry(row, false)
			entries.append(norm)
			var uid := str(norm.get("run_uid", ""))
			if _has_local_run(uid) and not is_run_synced(uid):
				_mark_run_synced(uid, row)
				local_dirty = true
	if local_dirty:
		_save_local_data()
	_sort_entries(entries)
	_remote_cache[cat] = entries
	_remote_loaded[cat] = true
	rankings_loaded.emit(cat, _merge_with_local(cat, entries), true, "")

func submit_current_run(raw_player_name: String):
	if not GameState.victory_achieved:
		submission_finished.emit(false, {}, "Conclua a campanha resgatando o Barão Ragnar para enviar um tempo.")
		return

	var val_err := validate_player_name(raw_player_name)
	if val_err != "":
		submission_finished.emit(false, {}, val_err)
		return

	var entry := record_local_run(raw_player_name)
	var uid := str(entry["run_uid"])

	if bool(entry.get("synced", false)):
		submission_finished.emit(true, entry, "")
		return

	if float(entry["time_seconds"]) < MIN_GLOBAL_TIME_SECONDS:
		submission_finished.emit(false, entry, "Tempo abaixo de 10s foi salvo nos Meus Recordes locais, mas não entra no Rank Global.")
		return

	var url := "%s/rest/v1/%s" % [SUPABASE_URL, TABLE_NAME]
	var body_dict := {
		"run_uid": uid,
		"player_name": entry["player_name"],
		"category": entry["category"],
		"time_seconds": entry["time_seconds"],
		"level": entry["level"],
		"total_kills": entry["total_kills"],
		"bosses_defeated": entry["bosses_defeated"],
		"game_version": entry["game_version"]
	}
	var json_body := JSON.stringify(body_dict)

	if OS.has_feature("web"):
		var web_headers := {
			"apikey": SUPABASE_PUBLISHABLE_KEY,
			"Accept": "application/json",
			"Content-Type": "application/json",
			"Prefer": "return=representation"
		}
		_web_fetch_async(url, "POST", web_headers, json_body, func(ok: bool, status: int, body_txt: String, err_msg: String):
			_handle_submit_response(ok, status, body_txt, err_msg, uid, entry)
		)
		return

	if is_instance_valid(_active_submit_req):
		_active_submit_req.cancel_request()
		_active_submit_req.queue_free()

	var req := HTTPRequest.new()
	req.use_threads = false
	req.accept_gzip = false
	req.timeout = 10.0
	add_child(req)
	_active_submit_req = req

	var headers := _make_headers([
		"Content-Type: application/json",
		"Prefer: return=representation"
	])

	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if is_instance_valid(req):
			req.queue_free()
		if _active_submit_req == req:
			_active_submit_req = null
		var ok := (result == HTTPRequest.RESULT_SUCCESS)
		var err_str := "" if ok else "sem conexão ou tempo esgotado (código %d)" % result
		_handle_submit_response(ok, response_code, body.get_string_from_utf8(), err_str, uid, entry)
	)

	var err := req.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		if is_instance_valid(req):
			req.queue_free()
		_active_submit_req = null
		submission_finished.emit(false, entry, "Salvo localmente. Sem conexão para enviar ao ranking global.")

func _handle_submit_response(ok: bool, response_code: int, body_txt: String, net_err: String, uid: String, entry: Dictionary):
	if ok and (response_code == 200 or response_code == 201):
		var parsed = JSON.parse_string(body_txt)
		var remote_row: Dictionary = {}
		if parsed is Array and parsed.size() > 0 and parsed[0] is Dictionary:
			remote_row = parsed[0]
		_mark_run_synced(uid, remote_row)
		entry["synced"] = true
		fetch_global_rankings(entry["category"])
		submission_finished.emit(true, entry, "")
		return

	if ok and response_code == 409:
		_mark_run_synced(uid)
		entry["synced"] = true
		fetch_global_rankings(entry["category"])
		submission_finished.emit(true, entry, "")
		return

	var msg := net_err if not ok else _describe_http_status(response_code, body_txt)
	submission_finished.emit(false, entry, "Salvo localmente, mas falhou ao enviar online: " + msg)

func _describe_http_status(response_code: int, body_txt: String) -> String:
	var parsed = JSON.parse_string(body_txt)
	if parsed is Dictionary and parsed.has("message"):
		return "HTTP %d (%s)" % [response_code, str(parsed["message"])]
	return "HTTP %d" % response_code

func _describe_http_error(result: int, response_code: int, body: PackedByteArray) -> String:
	if result != HTTPRequest.RESULT_SUCCESS:
		return "sem conexão ou tempo esgotado (código %d)" % result
	return _describe_http_status(response_code, body.get_string_from_utf8())
