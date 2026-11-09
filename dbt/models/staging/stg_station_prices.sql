-- One row per station and day as published, with Spanish decimals ("1,459") parsed.
SELECT
    CAST(price_date AS DATE)                                              AS price_date,
    station_id,
    upper(trim(brand))                                                    AS brand,
    province,
    municipality,
    postal_code,
    address,
    TRY_CAST(replace(latitude, ',', '.') AS DOUBLE)                       AS latitude,
    TRY_CAST(replace(longitude, ',', '.') AS DOUBLE)                      AS longitude,
    TRY_CAST(replace(nullif(price_gasoline_95, ''), ',', '.') AS DOUBLE)  AS price_gasoline_95,
    TRY_CAST(replace(nullif(price_diesel, ''), ',', '.') AS DOUBLE)       AS price_diesel,
    filename                                                              AS _source_file
FROM read_json('{{ var("bronze_dir") }}/date=*/prices.ndjson.gz', format = 'newline_delimited', filename = true,
               columns = {price_date: 'VARCHAR', station_id: 'VARCHAR', brand: 'VARCHAR', province: 'VARCHAR',
                          municipality: 'VARCHAR', postal_code: 'VARCHAR', address: 'VARCHAR', latitude: 'VARCHAR',
                          longitude: 'VARCHAR', price_gasoline_95: 'VARCHAR', price_diesel: 'VARCHAR'})
