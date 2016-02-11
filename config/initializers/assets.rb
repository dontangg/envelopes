# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'stylesheets', 'images')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w(
  ui-bg_flat_0_aaaaaa_40x100.png
  ui-bg_flat_75_ffffff_40x100.png
  ui-bg_glass_55_fbf9ee_1x400.png
  ui-bg_glass_65_ffffff_1x400.png
  ui-bg_glass_75_dadada_1x400.png
  ui-bg_glass_75_e6e6e6_1x400.png
  ui-bg_glass_95_fef1ec_1x400.png
  ui-bg_highlight-soft_75_cccccc_1x100.png
  ui-icons_2e83ff_256x240.png
  ui-icons_222222_256x240.png
  ui-icons_454545_256x240.png
  ui-icons_888888_256x240.png
  ui-icons_cd0a0a_256x240.png
)
