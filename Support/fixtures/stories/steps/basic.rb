require "foo_bar_baz"

steps_for(:basic) do
  include_steps_for :global

  Given "Basic step (given)" do
    Foo.should_not_error
  end
  
  Given "another basic step" do
    
  end
  
  Given %r{Basic regexp \(given\)} do 
    
  end
  
  When "Basic when" do
    
  end
  
  Then "Basic then" do
    
  end
end