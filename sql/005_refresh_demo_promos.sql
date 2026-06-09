update promos
set
  start_date = case
    when product_name = 'Minyak Goreng Hemat 2L' and brand = 'SunFresh' then current_date - 1
    when product_name = 'Beras Premium 5kg' and brand = 'Makmur' then current_date - 2
    when product_name = 'Susu UHT Cokelat 1L' and brand = 'Milko' then current_date - 1
    when product_name = 'Deterjen Cair 800ml' and brand = 'CleanPro' then current_date - 3
    when product_name = 'Keripik Kentang Family Pack' and brand = 'Crunchy' then current_date - 1
    when product_name = 'Teh Botol 450ml' and brand = 'FreshTea' then current_date - 1
    when product_name = 'Susu Bubuk Anak 800g' and brand = 'NutriKids' then current_date - 2
    when product_name = 'Minyak Goreng 1L' and brand = 'Golden Drop' then current_date - 1
    when product_name = 'Beras Ramos 2.5kg' and brand = 'Sawah Indah' then current_date - 1
    when product_name = 'Air Mineral 600ml' and brand = 'AquaFresh' then current_date - 1
    else start_date
  end,
  end_date = case
    when product_name = 'Minyak Goreng Hemat 2L' and brand = 'SunFresh' then current_date + 2
    when product_name = 'Beras Premium 5kg' and brand = 'Makmur' then current_date + 4
    when product_name = 'Susu UHT Cokelat 1L' and brand = 'Milko' then current_date + 1
    when product_name = 'Deterjen Cair 800ml' and brand = 'CleanPro' then current_date + 5
    when product_name = 'Keripik Kentang Family Pack' and brand = 'Crunchy' then current_date + 6
    when product_name = 'Teh Botol 450ml' and brand = 'FreshTea' then current_date + 2
    when product_name = 'Susu Bubuk Anak 800g' and brand = 'NutriKids' then current_date + 7
    when product_name = 'Minyak Goreng 1L' and brand = 'Golden Drop' then current_date + 3
    when product_name = 'Beras Ramos 2.5kg' and brand = 'Sawah Indah' then current_date + 5
    when product_name = 'Air Mineral 600ml' and brand = 'AquaFresh' then current_date + 2
    else end_date
  end,
  is_active = true
where (product_name, brand) in (
  ('Minyak Goreng Hemat 2L', 'SunFresh'),
  ('Beras Premium 5kg', 'Makmur'),
  ('Susu UHT Cokelat 1L', 'Milko'),
  ('Deterjen Cair 800ml', 'CleanPro'),
  ('Keripik Kentang Family Pack', 'Crunchy'),
  ('Teh Botol 450ml', 'FreshTea'),
  ('Susu Bubuk Anak 800g', 'NutriKids'),
  ('Minyak Goreng 1L', 'Golden Drop'),
  ('Beras Ramos 2.5kg', 'Sawah Indah'),
  ('Air Mineral 600ml', 'AquaFresh')
);
