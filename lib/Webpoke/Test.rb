=begin rdoc
  A test
=end
class Webpoke::Test
  
  mark_accessible :description, :group, :url, :method, :success, :query, :should_fail, :headers, :data, :body, :on_success, :dependant, :depends_on, :response, :parse, :metadata, :run_always
  
  def initialize(&block)
    @parse = true
    @on_success = [];
    instance_eval(&block);
    @group = @group || ''
    @method = @method || 'get'
    @headers = @headers || {}
    @on_success = [];
    @ran = false;
  end
  
  def should_parse?
    return @parse
  end
  
  def did_run?
    @ran
  end
  
  def on (response, &block)
    
    if (response == 'success')
      @on_success << block
    else
      @on_error << block
    end
    
  end
  
  def depends_on otherTest
    otherTest.on_success << self
    self.dependant = true;
  end
  
  def default_success (code, body)
    if @should_fail
      return code > 399
    else
      return (200..226).include?(code)
    end
  end
  
  def success (&block)
    @success = block
  end
  
=begin rdoc
Returns the test description


=end
  def to_s
    @description
  end
  
  
  def pt(v)
    clase = v.class.to_s
    case clase
    when 'Fixnum'
      clase = 'Int'
    when 'Hash'
      v.each do |k,nv|
        v[k] = self.pt(nv)
      end
      return v
      
    when 'TrueClass', 'FalseClass'
      clase = 'Boolean'
    end
    
    clase.downcase
  end
  
=begin rdoc
  Returns the test description definition (so that we can auto-generate documentation)
=end  
  def describe
    
    query = []
    if (@query)
      @query.each do |k,v|
        query << {key: k, v:self.pt(v)}
      end
    end
    
    data = []
    if (@data)
      @data.each do |k,v|
        data << {key: k, v:self.pt(v)}
      end
    end
    
    return {
      description: @description,
      url: @url,
      method: @method,
      query: query,
      headers: @headers,
      data: data,
      sampleOutput: @sampleOutput,
      metadata: @metadata
    }
    
  end
  
  
  def dependant?
    @dependant
  end
  
  
=begin rdoc
  Run the test
=end
  def passed? (response, body)
    @ran = true
    @response = {
      body: body,
      code: response
    }
    if !self.default_success(response, body)
      return false
    end
    
    
    if @success
      begin
        result = @success.call(response, body)
      rescue Exception => e
        result = false
        raise Webpoke::TestSuccessError.new(e.message, e)
      end
    else
      result = self.default_success(response, body)
    end
    
    return result
    
  end
  
end

class Webpoke::TestError < StandardError
  attr_accessor :object
  def initialize(message=nil, object=nil)
    super(message)
    self.object = object
  end
end
class Webpoke::TestSuccessError < Webpoke::TestError
end
class Webpoke::TestHTTPError < Webpoke::TestError
end
class Webpoke::TestParseError < Webpoke::TestError
end
