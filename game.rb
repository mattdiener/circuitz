#THIS GAME IS A HACK
require 'gosu'
require 'json'
require 'fileutils'
require 'io/console'

#Z coordinate
$bgZ = 0
$tileZ = 1
$gridZ = 2
$overlayZ = 3

#ROTATION HELPERS
$rotation_down = 0
$rotation_left = 1
$rotation_up = 2
$rotation_right = 3

#COLORS
$colorBrown = Gosu::Color.new(0xff594631)
$colorGrey = Gosu::Color.new(0xffA8A19C)
$colorBeige = Gosu::Color.new(0xffD9C0A1)
$colorCoffee = Gosu::Color.new(0xff2E1C05)
$colorTan = Gosu::Color.new(0xffA8896C)
$colorWhite = Gosu::Color.new(0xffffffff)
$colorBlack = Gosu::Color.new(0xff000000)
$colorRed = Gosu::Color.new(0xffff0000)

#TILES
$tileSourceSize = 16
$tileSprites = *Gosu::Image.load_tiles("./puzzletiles.png", $tileSourceSize, $tileSourceSize, {retro: true})

#SETTINGS
$tileSize = 128
$minBorder = 32
$animationTime = 16
$animationTimer = 0

#MOUSE
$mouseBoxX = -1
$mouseBoxY = -1
$mouseCanClick = false

#DEBUG
$debug_mode = false
$show_rotations = false
$debug_box_x = -1
$debug_box_y = -1
$enable_level_completion = true

class GearsGame < Gosu::Window
  def initialize
    super 640, 480

    self.caption = "Circuitz"
    $default_font = Gosu::Font.new(self, Gosu::default_font_name, 24)

    load_level("world1/level1")

    STDOUT.sync = true

    @debug_console_thread = Thread.new do handle_console end
  end

  def close
    super
    STDIN.ungetc("\n")
    STDIN.ungetc("!")
    @debug_console_thread.kill
  end

  def handle_console
    STDIN.each_line do |line|
      command, *args = line.split(" ")

      case command
      when "save"
        save_current_level_as(args[0], false) if args[0]
      when "save_hard"
        save_current_level_as(args[0], true) if args[0]
      when "load"
        load_level(args[0]) if args[0]
      when "!"
        puts "Byebye"
        STDIN.close()
        return
      end

    rescue => e
      puts e
    end
  end

  def save_current_level_as(name, force)
    level_file = "levels/#{name}.json"

    backboard = Array.new($tileCountW*$tileCountH)
    tiles = Array.new($tileCountW*$tileCountH)

    index = 0
    for x in 1..$tileCountW
      for y in 1..$tileCountH
        tiles[index] = @tiles[index].to_serial
        backboard[index] = @backboard[index].to_serial
        index += 1
      end
    end

    level = {
              'width' => $tileCountW,
              'height' => $tileCountH,
              'backboard' => backboard,
              'tiles' => tiles,
              'next_level' => ''
            }

    can_write = true

    if File.file?(level_file) and not force
      puts "file already exists with name: #{level_file} -- use save_hard to overwrite"
      can_write = false
    end

    if can_write
      dir = File.dirname(level_file)
      unless File.directory?(dir) 
        FileUtils.mkdir_p(dir)
      end

      f = File.new(level_file, 'w')
      f.write(JSON.pretty_generate(level))
      f.close()
    end
  end

  def button_down(btn)
    isAnimating = false
    if ($animationTimer > 0)
      self.update_animation()
      isAnimating = true
    end


    case btn
    when Gosu::KB_BACKTICK
      $debug_mode = (not $debug_mode)
    when Gosu::KB_F1
      $show_rotations = (not $show_rotations)
    when Gosu::KB_F2
      $enable_level_completion = (not $enable_level_completion)
    end

    if $debug_mode
      tile_index_a = tile_index($debug_box_x,$debug_box_y)
      tile_index_b = tile_index($debug_box_x,$debug_box_y)

      #debug only
      case btn
      when Gosu::KB_W
        #swap up
        if tile_exists?($debug_box_x,$debug_box_y) and
           tile_exists?($debug_box_x,$debug_box_y-1)
          tile_index_b = tile_index($debug_box_x,$debug_box_y-1)
          @tiles[tile_index_a].debug_translate(:up)
          @tiles[tile_index_b].debug_translate(:down)
          @tiles[tile_index_a], @tiles[tile_index_b] = @tiles[tile_index_b], @tiles[tile_index_a]
          $animationTimer = $animationTime
        end
      when Gosu::KB_A
        #swap left
        if tile_exists?($debug_box_x,$debug_box_y) and
           tile_exists?($debug_box_x-1,$debug_box_y)
          tile_index_b = tile_index($debug_box_x-1,$debug_box_y)
          @tiles[tile_index_a].debug_translate(:left)
          @tiles[tile_index_b].debug_translate(:right)
          @tiles[tile_index_a], @tiles[tile_index_b] = @tiles[tile_index_b], @tiles[tile_index_a]
          $animationTimer = $animationTime
        end
      when Gosu::KB_S
        #swap down
        if tile_exists?($debug_box_x,$debug_box_y) and
           tile_exists?($debug_box_x,$debug_box_y+1)
          tile_index_b = tile_index($debug_box_x,$debug_box_y+1)
          @tiles[tile_index_a].debug_translate(:down)
          @tiles[tile_index_b].debug_translate(:up)
          @tiles[tile_index_a], @tiles[tile_index_b] = @tiles[tile_index_b], @tiles[tile_index_a]
          $animationTimer = $animationTime
        end
      when Gosu::KB_D
        #swap right
        if tile_exists?($debug_box_x,$debug_box_y) and
           tile_exists?($debug_box_x+1,$debug_box_y)
          tile_index_b = tile_index($debug_box_x+1,$debug_box_y)
          @tiles[tile_index_a].debug_translate(:right)
          @tiles[tile_index_b].debug_translate(:left)
          @tiles[tile_index_a], @tiles[tile_index_b] = @tiles[tile_index_b], @tiles[tile_index_a]
          $animationTimer = $animationTime
        end
      when Gosu::KB_Q
        #swap right
        if tile_exists?($debug_box_x,$debug_box_y)
          @tiles[tile_index_a].debug_rotate(-1)
          $animationTimer = $animationTime
        end
      when Gosu::KB_E
        #swap right
        if tile_exists?($debug_box_x,$debug_box_y)
          @tiles[tile_index_a].debug_rotate(1)
          $animationTimer = $animationTime
        end
      when Gosu::KB_R
        @backboard[tile_index_a] = @backboard[tile_index_a].create_next_backboard_type()
      when Gosu::KB_T
        @tiles[tile_index_a] = @tiles[tile_index_a].create_next_tile_type()
      when Gosu::KB_I
        debug_size_board(:up)
      when Gosu::KB_J
        debug_size_board(:left)
      when Gosu::KB_K
        debug_size_board(:down)
      when Gosu::KB_L 
        debug_size_board(:right)
      end
    else
      #non-debug only

    end
  end

  def reset_mouse_box
    $mouseBoxX = -1
    $mouseBoxY = -1
    $mouseCanClick = false

    $debug_box_x = -1
    $debug_box_y = -1
  end

  def post_init
    end_animation()
  end

  def init_board(width, height)
    $tileCountW = width
    $tileCountH = height

    maxTileWidth = ((self.width-2*$minBorder)/$tileCountW)
    maxTileHeight = ((self.height-2*$minBorder)/$tileCountH)

    $tileSize = [maxTileWidth, maxTileHeight].min()

    $borderSides = (self.width - $tileCountW*$tileSize)/2
    $borderTopBottom = (self.height - $tileCountH*$tileSize)/2

    $innerX = $borderSides
    $innerY = $borderTopBottom

    $innerWidth = self.width - (2 * $borderSides)
    $innerHeight = self.height - (2 * $borderTopBottom)

    $tileScale = $tileSize / $tileSourceSize
  end
  
  def init_tiles(tiles)
    @tiles = Array.new($tileCountW * $tileCountH)
    index = 0
    for y in 0..($tileCountH-1)
      for x in 0..($tileCountW-1)
        @tiles[index] = create_tile(x, y, tiles[index]["rotation"], tiles[index]["type"])
        index += 1
      end
    end
  end

  def init_backboard(backboard)
    @backboard = Array.new($tileCountW * $tileCountH)
    index = 0
    for y in 0..($tileCountH-1)
      for x in 0..($tileCountW-1)
        @backboard[index] = create_backboard_square(x, y, backboard[index])
        index += 1
      end
    end
  end

  def debug_size_board(direction)
    height_new = $tileCountH
    width_new = $tileCountW

    case direction
    when :up
      height_new -= 1
    when :left
      width_new -= 1
    when :down
      height_new += 1
    when :right
      width_new += 1
    end

    if height_new < 1
      height_new = 1
    end

    if width_new < 1
      width_new = 1
    end

    xMax = [width_new, $tileCountW].min() - 1
    yMax = [height_new, $tileCountH].min() - 1
    
    tiles_new = Array.new(width_new, height_new)
    backboard_new = Array.new(width_new, height_new)

    index = 0
    for y in 0..height_new-1
      for x in 0..width_new-1
        if tile_in_range?(x,y)
          old_index = tile_index(x,y)
          tiles_new[index] = @tiles[old_index]
          tiles_new[index].set_position(x,y)
          backboard_new[index] = @backboard[old_index]
          backboard_new[index].set_position(x,y)
        else
          tiles_new[index] = create_tile(x, y, 0, "n")
          tiles_new[index].set_position(x,y)
          backboard_new[index] = create_backboard_square(x, y, "n")
        end
        index += 1
      end
    end

    init_board(width_new, height_new)

    @tiles = tiles_new
    @backboard = backboard_new

    reset_mouse_box()
  end

  def floor_to_power_of_two(num)
    return 2**(Math.log2(num).floor())
  end

  def needs_cursor?
    return true
  end

  def tile_exists?(x, y)
    return @backboard[tile_index(x,y)].exists? if tile_in_range?(x, y)
    return false
  end

  def tile_in_range?(x, y)
    return ((x >= 0) and (x < $tileCountW) and (y >= 0) and (y < $tileCountH))
  end

  def tile_can_rotate?(x, y)
    if((x >= 0) and (x < $tileCountW) and (y >= 0) and (y < $tileCountH))
      return @backboard[tile_index(x,y)].can_rotate?
    end
  end

  def tile_index(x, y)
    return y*$tileCountW + x
  end

  def send_signal(x, y, signal)
    @tiles[tile_index(x, y)].receive_signal(signal) if tile_exists?(x, y)
  end

  def update
    isAnimating = false

    if ($animationTimer > 0)
      self.update_animation()
      isAnimating = true
    end

    #UPDATE MOUSE POSITION
    tmpMouseBoxX = $mouseBoxX
    tmpMouseBoxY = $mouseBoxY

    if self.mouse_x > $innerX and self.mouse_x <= ($innerX + ($tileSize * $tileCountW))
      tmpMouseBoxX = (self.mouse_x - $borderSides).div($tileSize)
    else
      tmpMouseBoxX = -1
    end

    if self.mouse_y > $innerY and self.mouse_y <= ($innerY + ($tileSize * $tileCountH))
      tmpMouseBoxY = (self.mouse_y - $borderTopBottom).div($tileSize)
    else
      tmpMouseBoxY = -1
    end

    mouseMoved = false

    if(self.tile_exists?(tmpMouseBoxX,tmpMouseBoxY) and
       self.tile_exists?(tmpMouseBoxX+1,tmpMouseBoxY) and
       self.tile_exists?(tmpMouseBoxX,tmpMouseBoxY+1) and
       self.tile_exists?(tmpMouseBoxX+1,tmpMouseBoxY+1))
      # --- --- --- --- --- --- --- --- --- --- --- --- #
      $mouseBoxX = tmpMouseBoxX
      $mouseBoxY = tmpMouseBoxY
      mouseMoved = true
    end

    $mouseCanClick = false if mouseMoved

    if(self.tile_can_rotate?(tmpMouseBoxX,tmpMouseBoxY) and
       self.tile_can_rotate?(tmpMouseBoxX+1,tmpMouseBoxY) and
       self.tile_can_rotate?(tmpMouseBoxX,tmpMouseBoxY+1) and
       self.tile_can_rotate?(tmpMouseBoxX+1,tmpMouseBoxY+1))
      # --- --- --- --- --- --- --- --- --- --- --- --- #
      $mouseCanClick = true
    end

    if((tmpMouseBoxX >= 0) and (tmpMouseBoxX < $tileCountW) and (tmpMouseBoxY >= 0) and (tmpMouseBoxY < $tileCountH))
      $debug_box_x = tmpMouseBoxX
      $debug_box_y = tmpMouseBoxY
    end

    return if isAnimating or $debug_mode
    
    #REACT TO CLICKS
    if self.button_down?(Gosu::MsLeft) and $mouseCanClick
      idx_0 = tile_index($mouseBoxX, $mouseBoxY)#$mouseBoxY*$tileCountW + $mouseBoxX
      idx_1 = idx_0 + 1
      idx_2 = tile_index($mouseBoxX, $mouseBoxY+1)#($mouseBoxY+1)*$tileCountW + $mouseBoxX
      idx_3 = idx_2 + 1

      @tiles[idx_0].rotate(1, 0)
      @tiles[idx_1].rotate(1, 1)
      @tiles[idx_2].rotate(1, 2)
      @tiles[idx_3].rotate(1, 3)

      #We want to swap their indeces so we can continue to use the array to find the tiles properly
      tmp = @tiles[idx_0]
      @tiles[idx_0] = @tiles[idx_2]
      @tiles[idx_2] = @tiles[idx_3]
      @tiles[idx_3] = @tiles[idx_1]
      @tiles[idx_1] = tmp

      $animationTimer = $animationTime
    elsif self.button_down?(Gosu::MsRight) and $mouseCanClick
      idx_0 = $mouseBoxY*$tileCountW + $mouseBoxX
      idx_1 = idx_0 + 1
      idx_2 = ($mouseBoxY+1)*$tileCountW + $mouseBoxX
      idx_3 = idx_2 + 1

      @tiles[idx_0].rotate(-1, 0)
      @tiles[idx_1].rotate(-1, 1)
      @tiles[idx_2].rotate(-1, 2)
      @tiles[idx_3].rotate(-1, 3)

      #We want to swap their indeces so we can continue to use the array to find the tiles properly
      tmp = @tiles[idx_0]
      @tiles[idx_0] = @tiles[idx_1]
      @tiles[idx_1] = @tiles[idx_3]
      @tiles[idx_3] = @tiles[idx_2]
      @tiles[idx_2] = tmp

      $animationTimer = $animationTime
    end
  end
  
  def draw
    self.draw_bg()
    self.draw_tiles()
    self.draw_backboard()
    self.draw_mouse_box()
    self.draw_overlay()
  end

  def level_done?
    level_done = true
    index = 0
    for y in 0..($tileCountH-1)
      for x in 0..($tileCountW-1)
        level_done = false if not @tiles[index].condition_satisfied?
        index += 1
      end
    end

    return level_done
  end

  def update_animation
    $animationTimer -= 1
    end_animation() if $animationTimer == 0
  end

  def end_animation()
    index = 0
    for x in 1..$tileCountW
      for y in 1..$tileCountH
        @tiles[index].end_animation()
        index += 1
      end
    end

    index = 0
    for x in 1..$tileCountW
      for y in 1..$tileCountH
        @tiles[index].receive_signal(:on)
        index += 1
      end
    end

    if @fade_state == :in
      @fade_state = :none
    elsif @fade_state == :out
      load_level(@next_level)
    elsif level_done? and $enable_level_completion
      @fade_state = :out
      $animationTimer = $animationTime
    end
  end

  def draw_bg
    Gosu.draw_rect(0,0,self.width,self.height,$colorGrey, $bgZ)
  end

  def draw_tiles
    index = 0
    animationProgress = ($animationTime-$animationTimer)/($animationTime*1.0)
    for x in 1..$tileCountW
      for y in 1..$tileCountH
        @tiles[index].draw(animationProgress)
        index += 1
      end
    end
  end

  def draw_backboard
    index = 0
    for x in 1..$tileCountW
      for y in 1..$tileCountH
        @backboard[index].draw()
        index += 1
      end
    end
  end

  def draw_mouse_box
      outlineColor = $colorWhite

      if not $mouseCanClick
        outlineColor = $colorRed
      end

      #2 vertical lines and 2 horizontal
      if not $debug_mode
        if ($mouseBoxX < 0 or $mouseBoxY < 0)
          return
        end

        Gosu.draw_rect( $innerX + (($mouseBoxX+0)*$tileSize) - 1, $innerY + ($mouseBoxY*$tileSize) - 1, 3, $tileSize*2 + 3, outlineColor, $gridZ)
        Gosu.draw_rect( $innerX + (($mouseBoxX+2)*$tileSize) - 1, $innerY + ($mouseBoxY*$tileSize) - 1, 3, $tileSize*2 + 3, outlineColor, $gridZ)
        Gosu.draw_rect( $innerX + ($mouseBoxX*$tileSize) - 1, $innerY + (($mouseBoxY+0)*$tileSize) - 1, $tileSize*2 + 3, 3, outlineColor, $gridZ)
        Gosu.draw_rect( $innerX + ($mouseBoxX*$tileSize) - 1, $innerY + (($mouseBoxY+2)*$tileSize) - 1, $tileSize*2 + 3, 3, outlineColor, $gridZ)
      elsif $debug_mode 
        if ($debug_box_x < 0 or $debug_box_y < 0)
          return
        end

        debugColor = Gosu::Color::GREEN

        Gosu.draw_rect($innerX + (($debug_box_x+0)*$tileSize) - 1, $innerY + ($debug_box_y*$tileSize) - 1, 3, $tileSize + 3, debugColor, $gridZ)
        Gosu.draw_rect($innerX + (($debug_box_x+1)*$tileSize) - 1, $innerY + ($debug_box_y*$tileSize) - 1, 3, $tileSize + 3, debugColor, $gridZ)
        Gosu.draw_rect($innerX + ($debug_box_x*$tileSize) - 1, $innerY + (($debug_box_y+0)*$tileSize) - 1, $tileSize + 3, 3, debugColor, $gridZ)
        Gosu.draw_rect($innerX + ($debug_box_x*$tileSize) - 1, $innerY + (($debug_box_y+1)*$tileSize) - 1, $tileSize + 3, 3, debugColor, $gridZ)
      end
  end

  def draw_overlay
    animationProgress = ($animationTime-$animationTimer)/($animationTime*1.0)

    if $debug_mode
      #DEBUG_WARNING
      $default_font.draw_text("DEBUG",
                              0, 0, $overlayZ,
                              1, 1, Gosu::Color::GREEN)

      #BOX_SIZE
      $default_font.draw_text_rel("#{$tileCountW}x#{$tileCountH}",
                                   0, self.height, $overlayZ,
                                   0, 1.0, 1, 1, Gosu::Color::GREEN)
    end

    if not $enable_level_completion 
      color = Gosu::Color::RED
      if level_done?
        color = Gosu::Color::GREEN
      end

      $default_font.draw_text_rel("level transitions disabled",
                                   self.width, 0, $overlayZ,
                                   1.0, 0, 1, 1, color)
    end

    if @fade_state == :in
      color = Gosu::Color.new(255*(1-animationProgress),0,0,0)
      Gosu.draw_rect(0, 0, self.width, self.height, color, $overlayZ)
    elsif @fade_state == :out
      color = Gosu::Color.new(255*(animationProgress),0,0,0)
      Gosu.draw_rect(0, 0, self.width, self.height, color, $overlayZ)
    end
  end

  def create_tile(x, y, rotation, type)
    case type
    when "s"
      return SourceTile.new(x,y,rotation)
    when "k"
      return SinkTile.new(x,y,rotation)
    when "c"
      return CornerTile.new(x,y,rotation)
    when "l"
      return StraightTile.new(x,y,rotation)
    when "L"
      return OverUnderTile.new(x,y,rotation)
    when "C"
      return DoubleCornerTile.new(x,y,rotation)
    when "n"
      return NoTile.new(x,y,rotation)
    else
      return NoTile.new(x,y,rotation)
    end
  end

  def create_backboard_square(x, y, type)
    case type
    when "d"
      return BackboardSquare.new(x,y)
    when "s"
      return StaticBackboardSquare.new(x,y)
    when "n"
      return NoBackboardSquare.new(x,y)
    else
      return NoBackboardSquare.new(x,y)
    end
  end

  def load_level(name)
    return if not name or name == ''

    levelString = File.read(File.join("levels", name + ".json"))
    level = JSON.parse(levelString)

    init_board(level["width"], level["height"])
    init_backboard(level["backboard"])
    init_tiles(level["tiles"])

    @current_level = name
    @next_level = level["next_level"]

    reset_mouse_box()

    @fade_state = :in
    $animationTimer = $animationTime
  end

  class Tile
    def initialize(x, y, rotation)
      @x = x
      @y = y
      
      @xPrev = x
      @yPrev = y

      @rotation = rotation
      @rotationPrev = rotation

      @spriteIndex = 0
    end

    def type_letter
      return 'x'
    end

    def to_serial
      return  {
                'type' => type_letter, 
                'rotation' => @rotation
              }
    end

    def set_position(x, y)
      @x = x
      @y = y
    end

    def rotate(direction, boxPosition)
      @rotation += direction
      
      if (boxPosition == 0)
        if (direction == 1)
          @x += 1
        elsif (direction == -1)
          @y += 1
        end
      elsif (boxPosition == 1)
        if (direction == 1)
          @y += 1
        elsif (direction == -1)
          @x -= 1
        end
      elsif (boxPosition == 2)
        if (direction == 1)
          @y -= 1
        elsif (direction == -1)
          @x += 1
        end
      elsif (boxPosition == 3)
        if (direction == 1)
          @x -= 1
        elsif (direction == -1)
          @y -= 1
        end
      end
    end

    def debug_translate(direction)
      case direction
      when :down
        @y += 1
      when :up
        @y -= 1
      when :left
        @x -= 1
      when :right
        @x += 1
      end
    end

    def debug_rotate(direction)
      case direction
      when 1
        @rotation += 1
      when -1
        @rotation -= 1
      end
    end

    def draw(animationStage)
      refresh_sprite_index()

      dx = (@x-@xPrev) * animationStage
      dy = (@y-@yPrev) * animationStage
      dRot = (@rotation-@rotationPrev) * animationStage

      $tileSprites[@spriteIndex].draw_rot((@xPrev+dx) * $tileSize + $tileSize/2 + $innerX, 
                                         (@yPrev+dy) * $tileSize + $tileSize/2 + $innerY, 
                                         $tileZ, (@rotationPrev+dRot)*90, 0.5, 0.5, 
                                         $tileScale, $tileScale, 
                                         0xff_ffffff, :default)

      if $show_rotations
        $default_font.draw_text_rel(@rotation.to_s, 
                           @x*$tileSize + $tileSize/2 + $innerX, 
                           @y*$tileSize + $tileSize/2 + $innerY, 
                           $tileZ, 0.5, 0.5, $tileScale/2, $tileScale/2, Gosu::Color::BLUE)
      end
    end

    def end_animation()
      @xPrev = @x
      @yPrev = @y

      #normalize the rotations so we can have regular numbers for game logic
      while @rotation >= 4
        @rotation -= 4
      end

      while @rotation <= -1
        @rotation += 4
      end

      @rotationPrev = @rotation

      reset_signal()
    end

    def send_signal(side)
      dest_x = @x
      dest_y = @y
      dest_side = :none

      if side == :down
        dest_y += 1
        dest_side = :up
      elsif side == :left
        dest_x -= 1
        dest_side = :right
      elsif side == :up
        dest_y -= 1
        dest_side = :down
      elsif side == :right
        dest_x += 1
        dest_side = :left
      end

      $game.send_signal(dest_x, dest_y, dest_side)
    end

    def receive_signal(side)
      # :up, :right, :down, :left, :on
    end

    def reset_signal()
    end

    def refresh_sprite_index()
    end

    def condition_satisfied?()
      return true
    end

    def create_next_tile_type()
      return NoTile.new(@x, @y, @rotation)
    end
  end

  class NoTile < Tile
    def draw(animationStage)
      #noop
    end

    def type_letter
      return 'n'
    end

    def create_next_tile_type()
      return SourceTile.new(@x, @y, @rotation)
    end
  end

  class SourceTile < Tile
    def initialize(x, y, rotation)
      super(x, y, rotation)

      @isOn = false
      @offIndex = 0
      @onIndex = 1
    end
    
    def type_letter
      return 's'
    end

    def reset_signal()
      @isOn = false
    end

    def receive_signal(side)
      if side == :on and not @isOn
        @isOn = true

        if (@rotation == $rotation_down)
          send_signal(:down)
        elsif (@rotation == $rotation_left)
          send_signal(:left)
        elsif (@rotation == $rotation_up)
          send_signal(:up)
        elsif (@rotation == $rotation_right)
          send_signal(:right)
        end
      end
    end

    def refresh_sprite_index()
      if @isOn
        @spriteIndex = @onIndex
      else
        @spriteIndex = @offIndex
      end
    end

    def create_next_tile_type()
      return CornerTile.new(@x, @y, @rotation)
    end
  end

  class CornerTile < Tile
    def initialize(x, y, rotation)
      super(x, y, rotation)

      @isOn = false
      @offIndex = 4
      @onIndex = 5
    end

    def type_letter
      return 'c'
    end
    
    def reset_signal()
      @isOn = false
    end

    def in_signal_to_out_signal(side)
      out = :none

      case @rotation
      when $rotation_down
        if side == :down
          out = :right
        end
        if side == :right
          out = :down
        end
      when $rotation_left
        if side == :down
          out = :left
        end
        if side == :left
          out = :down
        end
      when $rotation_up
        if side == :left
          out = :up
        end
        if side == :up
          out = :left
        end
      when $rotation_right
        if side == :up
          out = :right
        end
        if side == :right
          out = :up
        end
      end

      return out
    end

    def receive_signal(side)
      out_side = in_signal_to_out_signal(side)

      if not @isOn and out_side != :none
        @isOn = true
        send_signal(out_side)
      end
    end

    def refresh_sprite_index()
      if @isOn
        @spriteIndex = @onIndex
      else
        @spriteIndex = @offIndex
      end
    end

    def create_next_tile_type()
      return StraightTile.new(@x, @y, @rotation)
    end
  end

  class StraightTile < Tile
    def initialize(x, y, rotation)
      super(x, y, rotation)

      @isOn = false
      @offIndex = 6
      @onIndex = 7
    end
    
    def type_letter
      return 'l'
    end

    def reset_signal()
      @isOn = false
    end

    def in_signal_to_out_signal(side)
      out = :none

      case @rotation
      when $rotation_down, $rotation_up
        if side == :down
          out = :up
        end
        if side == :up
          out = :down
        end
      when $rotation_left, $rotation_right
        if side == :right
          out = :left
        end
        if side == :left
          out = :right
        end
      end

      return out
    end

    def receive_signal(side)
      out_side = in_signal_to_out_signal(side)

      if not @isOn and out_side != :none
        @isOn = true
        send_signal(out_side)
      end
    end

    def refresh_sprite_index()
      if @isOn
        @spriteIndex = @onIndex
      else
        @spriteIndex = @offIndex
      end
    end

    def create_next_tile_type()
      return OverUnderTile.new(@x, @y, @rotation)
    end
  end

  class OverUnderTile < Tile
    def initialize(x, y, rotation)
      super(x, y, rotation)

      @isOnOver = false
      @isOnUnder = false

      @offIndex = 8
      @onOverIndex = 9
      @onUnderIndex = 10
      @onIndex = 11
    end
    
    def type_letter
      return 'L'
    end

    def reset_signal()
      @isOnOver = false
      @isOnUnder = false
    end

    def in_signal_to_out_signal(side)
      if side == :down
        return :up
      end
      if side == :up
        return :down
      end
      if side == :right
        return :left
      end
      if side == :left
        return :right
      end
    end

    def receive_signal(side)
      out_side = in_signal_to_out_signal(side)

      case @rotation
      when $rotation_up, $rotation_down
        if (out_side == :up or out_side == :down) and not @isOnUnder
          @isOnUnder = true
          send_signal(out_side)
        elsif (out_side == :left or out_side == :right) and not @isOnOver
          @isOnOver = true
          send_signal(out_side)
        end 
      when $rotation_left, $rotation_right
                if (out_side == :up or out_side == :down) and not @isOnOver
          @isOnOver = true
          send_signal(out_side)
        elsif (out_side == :left or out_side == :right) and not @isOnUnder
          @isOnUnder = true
          send_signal(out_side)
        end 
      end
    end

    def refresh_sprite_index()
      if @isOnOver and @isOnUnder
        @spriteIndex = @onIndex
      elsif @isOnOver
        @spriteIndex = @onOverIndex
      elsif @isOnUnder
        @spriteIndex = @onUnderIndex
      else
        @spriteIndex = @offIndex
      end
    end

    def create_next_tile_type()
      return DoubleCornerTile.new(@x, @y, @rotation)
    end
  end

  class DoubleCornerTile < Tile
    def initialize(x, y, rotation)
      super(x, y, rotation)

      @isOnA = false #down-right
      @isOnB = false #up-left

      @offIndex = 12
      @onAIndex = 13
      @onBIndex = 14
      @onIndex = 15
    end
    
    def type_letter
      return 'C'
    end

    def reset_signal()
      @isOnA = false
      @isOnB = false
    end

    def in_signal_to_out_signal(side)
      case @rotation
      when $rotation_up, $rotation_down
        if side == :down
          return :right
        end
        if side == :right
          return :down
        end
        if side == :up
          return :left
        end
        if side == :left
          return :up
        end
      when $rotation_left, $rotation_right
        if side == :down
          return :left
        end
        if side == :left
          return :down
        end
        if side == :up
          return :right
        end
        if side == :right
          return :up
        end
      end
    end

    def receive_signal(side)
      out_side = in_signal_to_out_signal(side)

      case @rotation
      when $rotation_down
        if (out_side == :down or out_side == :right) and not @isOnA
          @isOnA = true
          send_signal(out_side)
        elsif (out_side == :up or out_side == :left) and not @isOnB
          @isOnB = true
          send_signal(out_side)
        end 
      when $rotation_left
        if (out_side == :down or out_side == :left) and not @isOnA
          @isOnA = true
          send_signal(out_side)
        elsif (out_side == :up or out_side == :right) and not @isOnB
          @isOnB = true
          send_signal(out_side)
        end 
      when $rotation_up
        if (out_side == :up or out_side == :left) and not @isOnA
          @isOnA = true
          send_signal(out_side)
        elsif (out_side == :down or out_side == :right) and not @isOnB
          @isOnB = true
          send_signal(out_side)
        end 
      when $rotation_right
        if (out_side == :up or out_side == :right) and not @isOnA
          @isOnA = true
          send_signal(out_side)
        elsif (out_side == :down or out_side == :left) and not @isOnB
          @isOnB = true
          send_signal(out_side)
        end 
      end
    end

    def refresh_sprite_index()
      if @isOnA and @isOnB
        @spriteIndex = @onIndex
      elsif @isOnA
        @spriteIndex = @onAIndex
      elsif @isOnB
        @spriteIndex = @onBIndex
      else
        @spriteIndex = @offIndex
      end
    end

    def create_next_tile_type()
      return SinkTile.new(@x, @y, @rotation)
    end
  end

  class SinkTile < Tile
    def initialize(x, y, rotation)
      super(x, y, rotation)

      @isOn = false
      @offIndex = 2
      @onIndex = 3
    end

    def type_letter
      return 'k'
    end
    
    def reset_signal()
      @isOn = false
    end

    def receive_signal(side)
      if side == :down and @rotation == $rotation_down
        @isOn = true
      elsif side == :left and @rotation == $rotation_left
        @isOn = true
      elsif side == :up and @rotation == $rotation_up
        @isOn = true
      elsif side == :right and @rotation == $rotation_right
        @isOn = true
      end
    end

    def refresh_sprite_index()
      if @isOn
        @spriteIndex = @onIndex
      else
        @spriteIndex = @offIndex
      end
    end

    def condition_satisfied?()
      return @isOn
    end

    def create_next_tile_type()
      return NoTile.new(@x, @y, @rotation)
    end
  end

  class BackboardSquare
    def initialize(x, y)
      @x = x
      @y = y
    end

    def to_serial
      return 'd'
    end

    def set_position(x, y)
      @x = x
      @y = y
    end

    def can_rotate?
      return true
    end

    def exists?
      return true
    end

    def color
      return $colorBeige
    end

    def draw
      Gosu.draw_rect($innerX + @x*$tileSize,$innerY + @y*$tileSize, $tileSize, $tileSize, color(), $bgZ)

      # LINES
      lineColor = $colorCoffee

      # draw vertical lines
      Gosu.draw_rect( $innerX + (@x*$tileSize) - 1, $innerY + (@y*$tileSize) - 1, 3, $tileSize + 3, lineColor, $gridZ )
      Gosu.draw_rect( $innerX + ((@x+1)*$tileSize) - 1, $innerY + (@y*$tileSize) - 1, 3, $tileSize + 3, lineColor, $gridZ )

      # draw horizontal lines
      Gosu.draw_rect( $innerX + (@x*$tileSize) - 1, $innerY + (@y*$tileSize) - 1, $tileSize + 3, 3, lineColor, $gridZ )
      Gosu.draw_rect( $innerX + (@x*$tileSize) - 1, $innerY + ((@y+1)*$tileSize) - 1, $tileSize + 3, 3, lineColor, $gridZ )
    end

    def create_next_backboard_type()
      return StaticBackboardSquare.new(@x, @y)
    end
  end

  class StaticBackboardSquare < BackboardSquare
    def initialize(x, y)
      super(x, y)
    end

    def to_serial
      return 's'
    end

    def can_rotate?
      return false
    end

    def color
      return $colorBrown
    end

    def create_next_backboard_type()
      return NoBackboardSquare.new(@x, @y)
    end
  end

  class NoBackboardSquare < StaticBackboardSquare
    def initialize(x, y)
      super(x, y)
    end

    def to_serial
      return 'n'
    end

    def exists?
      return false
    end

    def draw
      #noop
    end

    def create_next_backboard_type()
      return BackboardSquare.new(@x, @y)
    end
  end
end

$game = GearsGame.new()
$game.post_init()
$game.show()