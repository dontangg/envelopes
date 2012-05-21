module ApplicationHelper
  def title(title)
    content_for(:title, title)
  end

  def show_mobile_head
    content_for(:mobile_head, '
      <!-- Mobile-specific tags -->
      <meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0" />
      <meta name="apple-mobile-web-app-capable" content="yes" />
      <meta name="apple-mobile-web-app-status-bar-style" content="black"> <!-- default, black, or black-translucent -->
      <!--link rel="apple-touch-icon" href="apple-touch-icon-57x57.png" /> or apple-touch-icon-57x57-precomposed.png for no gloss
      <link rel="apple-touch-icon" sizes="72x72" href="apple-touch-icon-72x72" />
      <link rel="apple-touch-icon" sizes="114x114" href="apple-touch-icon-114x114" /-->'.html_safe)
  end
end
