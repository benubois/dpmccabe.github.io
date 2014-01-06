require 'jekyll_asset_pipeline'

module JekyllAssetPipeline
  # process SCSS files
  class SassConverter < JekyllAssetPipeline::Converter
    require 'sass'
    require 'compass'

    def self.filetype
      '.scss'
    end

    def convert
      Sass::Engine.new(@content, syntax: :scss).render
    end
  end

  class CssCompressor < JekyllAssetPipeline::Compressor
    require 'yui/compressor'

    def self.filetype
      '.css'
    end

    def compress
      YUI::CssCompressor.new.compress(@content)
    end
  end
end
