package com.motion.catalogjoin.model;

import java.util.Map;

/** An ITEM_BALANCE row joined to its LOCATION_PROFILE row (null when the location is unknown). */
public record LocatedBalance(Map<String, Object> balance, Map<String, Object> location) {}
