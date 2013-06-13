class Class
  
  def mark_accessible (*args)
    args.each do |arg|
      self.class_eval("def #{arg} (val=nil); if (val) then @#{arg} = val; else @#{arg}; end end")
      self.class_eval("def #{arg}=(val);@#{arg}=val;end") 
    end
  end
  
end