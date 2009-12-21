module StringExt
  
  def to_slug
    self.downcase.tr(' ', '-').tr('.', '').tr('/', '-').tr(',', '')
  end
  
end

String.send :include, StringExt