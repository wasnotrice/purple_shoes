class Shoes
  class App
    def initialize shell
      @shell = shell
    end
    
    def para str, args={}
      label = Swt::Label.new @shell, Swt::SWT::LEFT
      label.setText str
      label.setLocation args[:left], args[:top]
      label.pack
    end
    
    def button name, args={}
      b = Swt::Button.new @shell, Swt::SWT::NULL
      b.setText name
      b.setLocation args[:left], args[:top]
      b.pack
      b.addSelectionListener do
        yield
      end if block_given?
    end
  end
end
