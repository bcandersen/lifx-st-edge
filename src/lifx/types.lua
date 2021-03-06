local types = {
  PROTOCOL_NUMBER = 1024, -- defined by LIFX protocol
  
  DEFAULT_PORT = 56700,
  DEFAULT_TRANSITION_TIME = 400,

  MSG_TYPE_GETLABEL = 23,
  MSG_TYPE_STATELABEL = 25,
  MSG_TYPE_GETVERSION = 32,
  MSG_TYPE_STATEVERSION = 33,
  MSG_TYPE_GET = 101,
  MSG_TYPE_STATE = 107,
  MSG_TYPE_GETPOWER = 116,
  MSG_TYPE_SETPOWER = 117,
  MSG_TYPE_STATEPOWER = 118,
  MSG_TYPE_SETWAVEFORMOPTIONAL = 119,

  HEADER_SIZE = 36,
  STATE_PAYLOAD_SIZE = 52,
  STATEVERSION_PAYLOAD_SIZE = 12,

  STATEPOWER_PAYLOAD_SIZE = 2,
  SETPOWER_PAYLOAD_SIZE = 6,
  SETWAVEFORMOPTIONAL_PAYLOAD_SIZE = 25,

  HEADER_OFFSET_SIZE = 0,

  HEADER_OFFSET_FLAGS = 2,
  HEADER_FLAGS_ORIGIN_BITS = 2,
  HEADER_FLAGS_ORIGIN_BITS_SHIFT = 14,
  HEADER_FLAGS_TAGGED_BITS = 1,
  HEADER_FLAGS_TAGGED_BITS_SHIFT = 13,
  HEADER_FLAGS_ADDRESSABLE_BITS = 1,
  HEADER_FLAGS_ADDRESSABLE_BITS_SHIFT = 12,
  HEADER_FLAGS_PROTOCOL_BITS = 12,
  HEADER_FLAGS_PROTOCOL_BITS_SHIFT = 0,

  HEADER_OFFSET_SOURCE = 4,
  HEADER_OFFSET_TARGET = 8,
  HEADER_OFFSET_REQUIRED = 22,
  HEADER_ACK_REQUIRED_BITS = 1,
  HEADER_ACK_REQUIRED_BITS_SHIFT = 1,
  HEADER_RES_REQUIRED_BITS = 1,
  HEADER_RES_REQUIRED_BITS_SHIFT = 0,

  HEADER_OFFSET_SEQ = 23,
  HEADER_OFFSET_TYPE = 32,

  STATE_PAYLOAD_HUE = 0,
  STATE_PAYLOAD_SATURATION = 2,
  STATE_PAYLOAD_BRIGHTNESS = 4,
  STATE_PAYLOAD_KELVIN = 6,
  STATE_PAYLOAD_POWER = 10,
  STATE_PAYLOAD_LABEL = 12,

  STATEVERSION_PAYLOAD_VENDOR = 0,
  STATEVERSION_PAYLOAD_PRODUCT = 4,
  STATEVERSION_PAYLOAD_VERSION = 8,

  PAYLOAD_OFFSET = 36, -- HEADER_SIZE
  SETWAVEFORMOPT_PAYLOAD_TRANSIENT_OFFSET = 1,
  SETWAVEFORMOPT_PAYLOAD_HUE_OFFSET = 2,
  SETWAVEFORMOPT_PAYLOAD_SAT_OFFSET = 4,
  SETWAVEFORMOPT_PAYLOAD_BRI_OFFSET = 6,
  SETWAVEFORMOPT_PAYLOAD_KEL_OFFSET = 8,
  SETWAVEFORMOPT_PAYLOAD_PERIOD_OFFSET = 10,
  SETWAVEFORMOPT_PAYLOAD_CYCLES_OFFSET = 14,
  SETWAVEFORMOPT_PAYLOAD_SKEW_RATIO_OFFSET = 18,
  SETWAVEFORMOPT_PAYLOAD_WAVEFORM = 20,
  SETWAVEFORMOPT_PAYLOAD_SET_HUE_OFFSET = 21,
  SETWAVEFORMOPT_PAYLOAD_SET_SAT_OFFSET = 22,
  SETWAVEFORMOPT_PAYLOAD_SET_BRI_OFFSET = 23,
  SETWAVEFORMOPT_PAYLOAD_SET_KEL_OFFSET = 24,

  SETPOWER_PAYLOAD_LEVEL_OFFSET = 0,
  SETPOWER_PAYLOAD_DURATION_OFFSET = 2,

  POWER_ON = 65535,

  MAX_HUE = 65535,
  MAX_SAT = 65535,
  MAX_BRIGHTNESS = 65535,
  MAX_KELVIN = 9000
}

return types
