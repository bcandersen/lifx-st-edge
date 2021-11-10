--------------------------------------------------------------------------------------------
-- LIFX Helper Utilities
--------------------------------------------------------------------------------------------

local products_json = require "lifx.products"
local json = require "dkjson"

local function get_model_name_from_product_id(id)
  local products_table, pos, decode_err = json.decode(products_json)
  if products_table == nil then
    return nil, "Error decoding products json: " .. decode_err
  end

  for i, product in ipairs(products_table.products) do
    if product.pid == id then
      return product.name
    end
  end

  return nil, "Failed to find product for given id: " .. id
end

local function get_color_support_from_product_id(id)
  local products_table, pos, decode_err = json.decode(products_json)
  if products_table == nil then
    return nil, "Error decoding products json: " .. decode_err
  end

  for i, product in ipairs(products_table.products) do
    if product.pid == id then
      if product.features then
        return product.features.color or false
      end

      return false
    end
  end

  return nil, "Failed to find product for given id: " .. id
end

local function get_color_temp_range_from_product_id(id)
  local products_table, pos, decode_err = json.decode(products_json)
  if products_table == nil then
    return nil, "Error decoding products json: " .. decode_err
  end

  for i, product in ipairs(products_table.products) do
    if product.pid == id then
      if product.features and product.features.temperature_range then
        return product.features.temperature_range
      else
        return nil, "failed to find color temperature range for id: " .. id
      end

      return false
    end
  end

  return nil, "Failed to find product for given id: " .. id
end

return {
  get_model_name_from_product_id = get_model_name_from_product_id,
  get_color_support_from_product_id = get_color_support_from_product_id,
  get_color_temp_range_from_product_id = get_color_temp_range_from_product_id
}
