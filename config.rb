###
# Page options, layouts, aliases and proxies
###

activate :syntax
set :relative_links, true
set :latest_release, '2017.6'
set :min_ruby_version, '2.1'
set :markdown, parse_block_html: true
activate :livereload
activate :relative_assets
activate :navtree do |options|
    options.data_file = 'tree.yml' # The data file where our navtree is stored.
    options.automatic_tree_updates = true # The tree.yml file will be updated automatically when source files are changed.
    options.ignore_files = ['sitemap.xml', 'robots.txt', 'about.html.md'] # An array of files we want to ignore when building our tree.
    options.ignore_dir = ['assets', 'media'] # An array of directories we want to ignore when building our tree.
    options.home_title = 'Home' # The default link title of the home page (located at "/"), if otherwise not detected.
    options.promote_files = [] # Any files we might want to promote to the front of our navigation
    options.ext_whitelist = [] # If you add extensions (like '.md') to this array, it builds a whitelist of filetypes for inclusion in the navtree.
    options.directory_indexes << 'index.html.md' << 'index.html.md.erb'
end
activate :deploy do |deploy|
    deploy.deploy_method = :git
    deploy.remote = "git@github.com:rock-core/rock-and-syskit.git"
    deploy.branch = "gh-pages"
    deploy.build_before = true
end

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

# General configuration

###
# Helpers
###

# Methods defined in the helpers block are available in templates
helpers do
    def load_svg(file)
        File.read(File.join(app.root, 'source', file))
    end
end

require "html-proofer"

after_build do |_builder|
    begin
        HTMLProofer.check_directory(
            config[:build_dir],
            { assume_extension: true,
              ignore_urls: [/rubydoc|gazebosim/],
              url_ignore: [/rubydoc|gazebosim/] }
        ).run
    rescue RuntimeError => e
        puts e
    end
end

# Build-specific configuration
configure :build do
  # Minify CSS on build
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript
end
