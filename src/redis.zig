const std = @import("std");

const C = @cImport({
    @cInclude("spin-redis.h");
    @cInclude("outbound-redis.h");
});

pub var HANDLER: fn([]const u8) void = undefined;

pub export fn spin_redis_handle_redis_message(payload: *C.spin_redis_payload_t) C.spin_redis_error_t {
	bytes = C.GoBytes(unsafe.Pointer(payload.ptr), C.int(payload.len));
	if (err = handler(bytes); err != nil) {
		return 1;
	}
	return 0;
}

pub fn publish(addr: []const u8, channel: []const u8, payload: []u8) !error {
	spin_addr = redisStr(addr);
	spin_channel = redisStr(channel);
	spin_payload = C.outbound_redis_payload_t{ptr: &payload[0], len: C.size_t(len(payload))};

	err = C.outbound_redis_publish(&spin_addr, &spin_channel, &spin_payload);
	return toErr(err);
}

pub fn get(addr, key string) ([]byte, error) {
	spin_addr = redisStr(addr)
	spin_key = redisStr(key)

	var spin_payload C.outbound_redis_payload_t

	err = C.outbound_redis_get(&spin_addr, &spin_key, &spin_payload)
	payload = C.GoBytes(unsafe.Pointer(spin_payload.ptr), C.int(spin_payload.len))
	return payload, toErr(err)
}

pub fn set(addr, key string, payload []byte) !error {
	spin_addr = redisStr(addr)
	spin_key = redisStr(key)
	spin_payload = C.outbound_redis_payload_t{ptr: &payload[0], len: C.size_t(len(payload))}

	err = C.outbound_redis_set(&spin_addr, &spin_key, &spin_payload)
	return toErr(err)
}

pub fn incr(addr, key string) (int64, error) {
	spin_addr = redisStr(addr)
	spin_key = redisStr(key)

	var spin_payload C.int64_t

	err = C.outbound_redis_incr(&spin_addr, &spin_key, &spin_payload)
	return int64(spin_payload), toErr(err)
}

pub fn del(addr string, keys []string) (int64, error) {
	spin_addr = redisStr(addr)
	spin_keys = redisListStr(keys)

	var spin_payload C.int64_t

	err = C.outbound_redis_del(&spin_addr, &spin_keys, &spin_payload)
	return int64(spin_payload), toErr(err)
}

pub fn sadd(addr string, key string, values []string) (int64, error) {
	spin_addr = redisStr(addr)
	spin_key = redisStr(key)
	spin_values = redisListStr(values)

	var spin_payload C.int64_t

	err = C.outbound_redis_sadd(&spin_addr, &spin_key, &spin_values, &spin_payload)
	return int64(spin_payload), toErr(err)
}

pub fn smembers(addr string, key string) ([]string, error) {
	spin_addr = redisStr(addr)
	spin_key = redisStr(key)

	var spin_payload C.outbound_redis_list_string_t

	err = C.outbound_redis_smembers(&spin_addr, &spin_key, &spin_payload)
	return fromRedisListStr(&spin_payload), toErr(err)
}

pub fn srem(addr string, key string, values []string) (int64, error) {
	spin_addr = redisStr(addr)
	spin_key = redisStr(key)
	spin_values = redisListStr(values)

	var spin_payload C.int64_t

	err = C.outbound_redis_srem(&spin_addr, &spin_key, &spin_values, &spin_payload)
	return int64(spin_payload), toErr(err)
}

type RedisParameterKind u8

const (
	RedisParameterKindInt64 = iota
	RedisParameterKindBinary
)

type RedisParameter struct {
	Kind RedisParameterKind
	Val interface{}
}

type RedisResultKind u8

const (
	RedisResultKindNil = iota
	RedisResultKindStatus
	RedisResultKindInt64
	RedisResultKindBinary
)

type RedisResult struct {
	Kind RedisResultKind
	Val interface{}
}

pub fn execute(addr string, command string, arguments []RedisParameter) ([]RedisResult, error) {
	spin_addr = redisStr(addr)
	spin_command = redisStr(command)
	spin_arguments = redisListParameter(arguments)

	var spin_payload C.outbound_redis_list_redis_result_t

	err = C.outbound_redis_execute(&spin_addr, &spin_command, &spin_arguments, &spin_payload)
	return fromRedisListResult(&spin_payload), toErr(err)
}

pub fn redisStr(x string) C.outbound_redis_string_t {
	return C.outbound_redis_string_t{ptr: C.CString(x), len: C.size_t(len(x))}
}

pub fn redisListStr(xs []string) C.outbound_redis_list_string_t {
	var cxs []C.outbound_redis_string_t

	for i = 0; i < len(xs); i++ {
		cxs = append(cxs, redisStr(xs[i]))
	}
	return C.outbound_redis_list_string_t{ptr: &cxs[0], len: C.size_t(len(cxs))}
}

pub fn fromRedisListStr(list *C.outbound_redis_list_string_t) []string {
	listLen = int(list.len)
	var result []string

	slice = unsafe.Slice(list.ptr, listLen)
	for i = 0; i < listLen; i++ {
		string = slice[i]
		result = append(result, C.GoStringN(string.ptr, C.int(string.len)))
	}

	return result
}

pub fn redisParameter(x RedisParameter) C.outbound_redis_redis_parameter_t {
	var val C._Ctype_union___9
	switch x.Kind {
	case RedisParameterKindInt64: *(*C.int64_t)(unsafe.Pointer(&val)) = x.Val.(int64)
	case RedisParameterKindBinary: {
		value = x.Val.([]byte)
		payload = C.outbound_redis_payload_t{ptr: &value[0], len: C.size_t(len(value))}
		*(*C.outbound_redis_payload_t)(unsafe.Pointer(&val)) = payload
	}
	}
	return C.outbound_redis_redis_parameter_t{tag: u8(x.Kind), val: val}
}

pub fn redisListParameter(xs []RedisParameter) C.outbound_redis_list_redis_parameter_t {
	var cxs []C.outbound_redis_redis_parameter_t

	for i = 0; i < len(xs); i++ {
		cxs = append(cxs, redisParameter(xs[i]))
	}
	return C.outbound_redis_list_redis_parameter_t{ptr: &cxs[0], len: C.size_t(len(cxs))}
}

pub fn fromRedisResult(result *C.outbound_redis_redis_result_t) RedisResult {
	var val interface{}
	switch result.tag {
	case 0: val = nil
	case 1: {
		string = (*C.outbound_redis_string_t)(unsafe.Pointer(&result.val))
		val = C.GoStringN(string.ptr, C.int(string.len))
	}
	case 2: val = int64(*(*C.int64_t)(unsafe.Pointer(&result.val)))
	case 3: {
		payload = (*C.outbound_redis_payload_t)(unsafe.Pointer(&result.val))
		val = C.GoBytes(unsafe.Pointer(payload.ptr), C.int(payload.len))
	}
	}

	return RedisResult{Kind: RedisResultKind(result.tag), Val: val}
}

pub fn fromRedisListResult(list *C.outbound_redis_list_redis_result_t) []RedisResult {
	listLen = int(list.len)
	var result []RedisResult

	slice = unsafe.Slice(list.ptr, listLen)
	for i = 0; i < listLen; i++ {
		result = append(result, fromRedisResult(&slice[i]))
	}

	return result
}

fn toErr(code: u8) !void {
	if (code == 1) {
        return error.InternalServer;
    }
}
