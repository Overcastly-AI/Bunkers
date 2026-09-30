package com.motion.catalogjoin.model;

import java.util.Map;

/** The item-grain document, keyed by ITEM_NO. Built up one join at a time. */
public record ItemDoc(
    Map<String, Object> item,
    Manufacturer manufacturer,
    Group<Map<String, Object>> itemRules,
    Group<Map<String, Object>> manufacturerRules,
    Group<Map<String, Object>> productGroupRules,
    Group<LocatedBalance> dcStock,
    Group<Map<String, Object>> costs,
    Group<StepProduct> stepProducts) {

  public static ItemDoc of(Map<String, Object> item) {
    return new ItemDoc(item, null, null, null, null, null, null, null);
  }

  public ItemDoc withManufacturer(Manufacturer value) {
    return new ItemDoc(item, value, itemRules, manufacturerRules, productGroupRules, dcStock, costs, stepProducts);
  }

  public ItemDoc withItemRules(Group<Map<String, Object>> value) {
    return new ItemDoc(item, manufacturer, value, manufacturerRules, productGroupRules, dcStock, costs, stepProducts);
  }

  public ItemDoc withManufacturerRules(Group<Map<String, Object>> value) {
    return new ItemDoc(item, manufacturer, itemRules, value, productGroupRules, dcStock, costs, stepProducts);
  }

  public ItemDoc withProductGroupRules(Group<Map<String, Object>> value) {
    return new ItemDoc(item, manufacturer, itemRules, manufacturerRules, value, dcStock, costs, stepProducts);
  }

  public ItemDoc withDcStock(Group<LocatedBalance> value) {
    return new ItemDoc(item, manufacturer, itemRules, manufacturerRules, productGroupRules, value, costs, stepProducts);
  }

  public ItemDoc withCosts(Group<Map<String, Object>> value) {
    return new ItemDoc(item, manufacturer, itemRules, manufacturerRules, productGroupRules, dcStock, value, stepProducts);
  }

  public ItemDoc withStepProducts(Group<StepProduct> value) {
    return new ItemDoc(item, manufacturer, itemRules, manufacturerRules, productGroupRules, dcStock, costs, value);
  }
}
