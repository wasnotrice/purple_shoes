class Shoes
  class App
    include Mod2
    
    def initialize args={}
      args.each do |k, v|
        instance_variable_set "@#{k}", v
      end
      App.class_eval do
        attr_accessor *(args.keys - [:width, :height, :title])
      end
      init_app_vars
      @top_slot, @cslot = nil, self
    end
    
    attr_accessor :cslot, :top_slot, :contents, :order
    attr_writer :mouse_button, :mouse_pos
    
    def stack args={}, &blk
      args[:app] = self
      Stack.new slot_attributes(args), &blk
    end
    
    def flow args={}, &blk
      args[:app] = self
      Flow.new slot_attributes(args), &blk
    end
    
    def textblock klass, font_size, *msg
      args = msg.last.class == Hash ? msg.pop : {}
      args = basic_attributes args
      args[:markup] = msg.map(&:to_s).join
      args[:size] ||= font_size
      args[:font] ||= (@font_family or 'sans')
      args[:stroke] ||= black
      line_height =  args[:size] * 2
      
      if !(args[:left].zero? and args[:top].zero?) and (args[:width].zero? or args[:height].zero?)
        args[:nocontrol], args[:width], args[:height] = true, self.width, self.height
        layout_control = false
      else
        layout_control = true
      end

      if args[:create_real] or !layout_control
        tl = Swt::TextLayout.new Shoes.display
        tl.setText args[:markup]
        font = Swt::Font.new Shoes.display, args[:font], args[:size], Swt::SWT::NORMAL
        fgc = Swt::Color.new Shoes.display, *args[:stroke]
        bgc = args[:fill] ? Swt::Color.new(Shoes.display, *args[:fill]) : nil
        style = Swt::TextStyle.new font, fgc, bgc
        tl.setStyle style, 0, args[:markup].length
        pl = Swt::PaintListener.new
        class << pl; self end.
        instance_eval do
          define_method :paintControl do |e|
            tl.setWidth args[:width]
            tl.draw e.gc, args[:left], args[:top]
	          args[:height] = line_height * tl.getLineCount
          end
        end
        @shell.addPaintListener pl
        args[:real] = tl
      else
        args[:real] = false
      end
      args[:app] = self
      klass.new args
    end

    def banner *msg; textblock Banner, 48, *msg; end
    def title *msg; textblock Title, 34, *msg; end
    def subtitle *msg; textblock Subtitle, 26, *msg; end
    def tagline *msg; textblock Tagline, 18, *msg; end
    def caption *msg; textblock Caption, 14, *msg; end
    def para *msg; textblock Para, 12, *msg; end
    def inscription *msg; textblock Para, 10, *msg; end
    
    def image name, args={}, &blk
      args = basic_attributes args
      args[:full_width] = args[:full_height] = 0
      img = Swt::Image.new Shoes.display, name
      args[:real], args[:app] = img, self
      
      Image.new(args).tap do |s|
        pl = Swt::PaintListener.new
        class << pl; self end.
        instance_eval do
          define_method :paintControl do |e|
            gc = e.gc
            gc.drawImage img, s.left, s.top
          end
        end
        @shell.addPaintListener pl
        clickable s, &blk
      end
    end

    def button name, args={}
      args = basic_attributes args
      b = Swt::Button.new @shell, Swt::SWT::NULL
      b.setText name
      b.setLocation args[:left], args[:top]
      if args[:width] > 0 and args[:height] > 0
        b.setSize args[:width], args[:height]
      else
        b.pack
      end
      args[:real], args[:text], args[:app] = b, name, self
      Button.new(args).tap do |s|
        b.addSelectionListener do
          yield s
        end if block_given?
      end
    end
    
    def animate n=10, &blk
      n, i = 1000 / n, 0
      Anim.new(@shell, n, &blk).tap do |a|
        Shoes.display.timerExec n, a
      end
    end
    
    def mouse
      [@mouse_button, @mouse_pos[0], @mouse_pos[1]]
    end
    
    def oval *attrs, &blk
      args = attrs.last.class == Hash ? attrs.pop : {}
      case attrs.length
        when 0, 1
        when 2; args[:left], args[:top] = attrs
        when 3; args[:left], args[:top], args[:radius] = attrs
        else args[:left], args[:top], args[:width], args[:height] = attrs
      end
      args = basic_attributes args
      args[:width].zero? ? (args[:width] = args[:radius] * 2) : (args[:radius] = args[:width]/2.0)
      args[:height] = args[:width] if args[:height].zero?
      args[:strokewidth] = ( args[:strokewidth] or strokewidth or 1 )
      args[:nocontrol] = args[:noorder] = true

      pat1 = (args[:stroke] or stroke)
      pat2 = (args[:fill] or fill)
      args[:real], args[:app] = :shape, self
      Oval.new(args).tap do |s|
        pl = Swt::PaintListener.new
        class << pl; self end.
        instance_eval do
          define_method :paintControl do |e|
            gc = e.gc
            gc.setAntialias Swt::SWT::ON
            sw = s.strokewidth
            if pat1
              gc.setForeground Swt::Color.new(Shoes.display, *pat1[0,3])
              gc.setAlpha(pat1[3] ? pat1[3]*255 : 255)
              sw.times{|i| gc.drawOval s.left+i, s.top+i, s.width-i*2-1, s.height-i*2-1}
            end
            if pat2
              gc.setBackground Swt::Color.new(Shoes.display, *pat2[0,3])
              gc.setAlpha(pat2[3] ? pat2[3]*255 : 255)
              gc.fillOval s.left+sw, s.top+sw, s.width-sw*2, s.height-sw*2
            end
          end
        end
        @shell.addPaintListener pl
        clickable s, &blk
      end
    end

    def rect *attrs, &blk
      args = attrs.last.class == Hash ? attrs.pop : {}
      case attrs.length
        when 0, 1
        when 2; args[:left], args[:top] = attrs
        when 3; args[:left], args[:top], args[:width] = attrs
        else args[:left], args[:top], args[:width], args[:height] = attrs
      end
      args[:height] = args[:width] unless args[:height]
      args[:strokewidth] = ( args[:strokewidth] or strokewidth or 1 )
      args[:curve] ||= 0
      args[:nocontrol] = args[:noorder] = true
      args = basic_attributes args

      pat1 = (args[:stroke] or stroke)
      pat2 = (args[:fill] or fill)
      args[:real], args[:app] = :shape, self
      Rect.new(args).tap do |s|
        pl = Swt::PaintListener.new
        class << pl; self end.
        instance_eval do
          define_method :paintControl do |e|
            gc = e.gc
            gc.setAntialias Swt::SWT::ON
            sw = s.strokewidth
            if pat1
              gc.setForeground Swt::Color.new(Shoes.display, *pat1[0,3])
              gc.setAlpha(pat1[3] ? pat1[3]*255 : 255)
              sw.times{|i| gc.drawRoundRectangle s.left+i, s.top+i, s.width-i*2-1, s.height-i*2-1, s.curve, s.curve}
            end
            if pat2
              gc.setBackground Swt::Color.new(Shoes.display, *pat2[0,3])
              gc.setAlpha(pat2[3] ? pat2[3]*255 : 255)
              gc.fillRoundRectangle s.left+sw, s.top+sw, s.width-sw*2, s.height-sw*2, s.curve, s.curve
            end
          end
        end
        @shell.addPaintListener pl
        clickable s, &blk
      end
    end

    def rgb r, g, b, l=1.0
      (r <= 1 and g <= 1 and b <= 1) ? [r*255, g*255, b*255, l] : [r, g, b, l]
    end
  
    %w[fill stroke strokewidth].each do |name|
      eval "def #{name} #{name}=nil; #{name} ? @#{name}=#{name} : @#{name} end"
    end

    def nostroke
      strokewidth 0
    end
    
    def nofill
      @fill = false
    end
    
    def flush
      Shoes.call_back_procs self
    end
  end
end
