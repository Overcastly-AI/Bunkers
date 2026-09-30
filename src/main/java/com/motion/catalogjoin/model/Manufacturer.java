package com.motion.catalogjoin.model;

import java.util.Map;

/** MFR_PROFILE joined to MFR_NAME on MFR_NAME_ID ({@code name} is null when there is no match). */
public record Manufacturer(Map<String, Object> profile, Map<String, Object> name) {}
