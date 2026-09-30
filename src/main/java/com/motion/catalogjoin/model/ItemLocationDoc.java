package com.motion.catalogjoin.model;

import java.util.Map;

/** The item-at-location document, keyed by ITEM_NO + MI_LOC. */
public record ItemLocationDoc(
    Group<Map<String, Object>> balances,
    Map<String, Object> nonCosBalance,
    Group<Map<String, Object>> localCosts,
    Map<String, Object> location) {

  public static ItemLocationDoc empty() {
    return new ItemLocationDoc(null, null, null, null);
  }

  public ItemLocationDoc withBalances(Group<Map<String, Object>> value) {
    return new ItemLocationDoc(value, nonCosBalance, localCosts, location);
  }

  public ItemLocationDoc withNonCosBalance(Map<String, Object> value) {
    return new ItemLocationDoc(balances, value, localCosts, location);
  }

  public ItemLocationDoc withLocalCosts(Group<Map<String, Object>> value) {
    return new ItemLocationDoc(balances, nonCosBalance, value, location);
  }

  public ItemLocationDoc withLocation(Map<String, Object> value) {
    return new ItemLocationDoc(balances, nonCosBalance, localCosts, value);
  }
}
