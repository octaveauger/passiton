# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.wrappers :bootstrap_form_horizontal, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label
    b.wrapper tag: :div, class: 'col-xs-9' do |ba|
      ba.use :input
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block' }
      ba.use :error, wrap_with: { tag: 'p', class: 'help-block' }
    end
  end

  config.form_class = 'form-horizontal'
  config.label_class = 'control-label col-xs-3'
  config.button_class = 'btn'
  config.error_notification_tag = :div
  config.error_notification_class = 'alert alert-danger'
  config.wrapper_mappings = { :boolean => :checkbox} #, :select => :dropdown }

  config.wrappers :checkbox, tag: :div, class: "col-xs-offset-3 col-xs-9", error_class: "has-error" do |b|
    b.use :html5
    b.wrapper tag: :div, class: "checkbox" do |ba|
      ba.use :input
    end
    b.use :hint,  wrap_with: { tag: :p, class: "help-block" }
    b.use :error, wrap_with: { tag: :span, class: "help-block" }
  end

  config.wrappers :dropdown, tag: :div, class: "col-xs-6", error_class: "has-error" do |b|
    b.use :html5
    b.wrapper tag: :div, class: "form-control" do |ba|
      ba.use :select
    end
    b.use :hint,  wrap_with: { tag: :p, class: "help-block" }
    b.use :error, wrap_with: { tag: :span, class: "help-block" }
  end

  config.wrappers :prepend, tag: 'div', class: "form-group", error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label
    b.wrapper tag: 'div', class: 'controls' do |input|
      input.wrapper tag: 'div', class: 'input-prepend' do |prepend|
        prepend.use :input
      end
      input.use :hint,  wrap_with: { tag: 'span', class: 'help-block' }
      input.use :error, wrap_with: { tag: 'span', class: 'help-inline' }
    end
  end

  config.wrappers :append, tag: 'div', class: "form-group", error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label
    b.wrapper tag: 'div', class: 'controls' do |input|
      input.wrapper tag: 'div', class: 'input-append' do |append|
        append.use :input
      end
      input.use :hint,  wrap_with: { tag: 'span', class: 'help-block' }
      input.use :error, wrap_with: { tag: 'span', class: 'help-inline' }
    end
  end

  # Wrappers for forms and inputs using the Twitter Bootstrap toolkit.
  # Check the Bootstrap docs (http://twitter.github.com/bootstrap)
  # to learn about the different styles for forms and inputs,
  # buttons and other elements.
  config.default_wrapper = :bootstrap_form_horizontal
end
