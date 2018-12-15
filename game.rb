#THIS GAME IS A HACK
require 'gosu'

#Z coordinate
$bgZ = 0
$tileZ = 1
$gridZ = 2

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

#TILES
$tileSourceSize = 16
$tileSprites = *Gosu::Image.load_tiles("./puzzletiles.png", $tileSourceSize, $tileSourceSize, {retro: true})

#SETTINGS
$tileSize = 128
$minBorder = 32
$animationTime = 16
$animationTimer = 0

#MOUSE
$mouseBoxX = 0
$mouseBoxY = 0

class GearsGame < Gosu::Window
  def initialize
    super 640, 480
    caption = "Circuitz"
    init_board(5,5,0)
    init_tiles()
  end

  def post_init
    end_animation()
  end

  def init_board(width, height, tiles)
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
  
  def init_tiles()
    @tiles = Array.new($tileCountW * $tileCountH)
    index = 0
    for y in 0..($tileCountH-1)
      for x in 0..($tileCountW-1)
        if index == 4
          @tiles[index] = SourceTile.new(x, y, 0, 0)
        else
          if index%2 == 0
            if index%4 == 0
              @tiles[index] = CornerTile.new(x, y, 1, 0)
            else
              @tiles[index] = CornerTile.new(x, y, 0, 0)
            end
          else
            if (index+1)%4 == 0
              @tiles[index] = StraightTile.new(x, y, 1, 0)
            else
              @tiles[index] = StraightTile.new(x, y, 0, 0)
            end
          end
        end
        index += 1
      end
    end
  end

  def floor_to_power_of_two(num)
    return 2**(Math.log2(num).floor())
  end

  def needs_cursor?
    return true
  end

  def tile_exists?(x, y)
    return ((x >= 0) and (x < $tileCountW) and (y >= 0) and (y < $tileCountH))
  end

  def tile_index(x, y)
    return y*$tileCountW + x
  end

  def send_signal(x, y, signal)
    if tile_exists?(x, y)
      @tiles[tile_index(x, y)].receive_signal(signal)
    end
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

    if(self.tile_exists?(tmpMouseBoxX,tmpMouseBoxY) and
       self.tile_exists?(tmpMouseBoxX+1,tmpMouseBoxY) and
       self.tile_exists?(tmpMouseBoxX,tmpMouseBoxY+1) and
       self.tile_exists?(tmpMouseBoxX+1,tmpMouseBoxY+1))
      # --- --- --- --- --- --- --- --- --- --- --- --- #
      $mouseBoxX = tmpMouseBoxX
      $mouseBoxY = tmpMouseBoxY
    end

    if isAnimating
      return
    end

    #REACT TO CLICKS
    if self.button_down?(Gosu::MsLeft)
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
    elsif self.button_down?(Gosu::MsRight)
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
    self.draw_mouse_box()
  end

  def update_animation
    $animationTimer -= 1

    if $animationTimer == 0
      end_animation()
    end
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
  end

  def draw_bg
    Gosu.draw_rect(0,0,self.width,self.height,$colorGrey, $bgZ)

    # draw inner area
    Gosu.draw_rect($innerX,$innerY,$innerWidth,$innerHeight,$colorBeige, $bgZ)

    # LINES
    lineColor = $colorCoffee

    # draw vertical lines    
    for lineX in 0..$tileCountW
      Gosu.draw_rect( $innerX + (lineX*$tileSize) - 1, $innerY - 1, 3, $innerHeight + 3, lineColor, $gridZ )
    end

    # draw horizontal lines
    for lineY in 0..$tileCountH
      Gosu.draw_rect( $innerX - 1, $innerY + (lineY*$tileSize) - 1, $innerWidth + 3, 3, lineColor, $gridZ )
    end
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

  def draw_mouse_box
      outlineColor = $colorWhite

      #2 vertical lines and 2 horizontal
      Gosu.draw_rect( $innerX + (($mouseBoxX+0)*$tileSize) - 1, $innerY + ($mouseBoxY*$tileSize) - 1, 3, $tileSize*2 + 3, outlineColor, $gridZ)
      Gosu.draw_rect( $innerX + (($mouseBoxX+2)*$tileSize) - 1, $innerY + ($mouseBoxY*$tileSize) - 1, 3, $tileSize*2 + 3, outlineColor, $gridZ)

      Gosu.draw_rect( $innerX + ($mouseBoxX*$tileSize) - 1, $innerY + (($mouseBoxY+0)*$tileSize) - 1, $tileSize*2 + 3, 3, outlineColor, $gridZ)
      Gosu.draw_rect( $innerX + ($mouseBoxX*$tileSize) - 1, $innerY + (($mouseBoxY+2)*$tileSize) - 1, $tileSize*2 + 3, 3, outlineColor, $gridZ)
  end

  class Tile
    def initialize(x, y, rotation, type)
      @x = x
      @y = y
      
      @xPrev = x
      @yPrev = y

      @rotation = rotation
      @rotationPrev = rotation

      @spriteIndex = 0
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
    end

    def end_animation()
      @xPrev = @x
      @yPrev = @y

      #normalize the rotations so we can have regular numbers for game logic
      if @rotation == 4
        @rotation = 0
      end

      if @rotation == -1
        @rotation = 3
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
  end

  class SourceTile < Tile
    def initialize(x, y, rotation, type)
      super(x, y, rotation, type)

      @isOn = false
      @offIndex = 0
      @onIndex = 1
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
  end

  class CornerTile < Tile
    def initialize(x, y, rotation, type)
      super(x, y, rotation, type)

      @isOn = false
      @offIndex = 4
      @onIndex = 5
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
  end

    class StraightTile < Tile
    def initialize(x, y, rotation, type)
      super(x, y, rotation, type)

      @isOn = false
      @offIndex = 6
      @onIndex = 7
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
  end
end

$game = GearsGame.new()
$game.post_init()
$game.show()