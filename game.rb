#THIS GAME IS A HACK
require 'gosu'

#Z coordinate
$bgZ = 0
$tileZ = 1
$gridZ = 2

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

#BOARD
$borderSides = 32
$borderTopBottom = 48

$tileSize = 64

$innerWidth = 0
$innerHeight = 0

$innerX = $borderSides
$innerY = $borderTopBottom

$tileCountW = 0
$tileCountH = 0

$mouseBoxX = 0
$mouseBoxY = 0

$animationTime = 16
$animationTimer = 0

$tileScale = $tileSize / $tileSourceSize

class GearsGame < Gosu::Window
  def initialize
    super 640, 480
    self.caption = "Circuitz"

    $innerWidth = self.width - (2 * $borderSides)
    $innerHeight = self.height - (2 * $borderTopBottom)

    $tileCountW = $innerWidth / $tileSize
    $tileCountH = $innerHeight / $tileSize

    @tiles = Array.new($tileCountW * $tileCountH)
    index = 0
    for y in 1..$tileCountH
      for x in 1..$tileCountW
        @tiles[index] = Tile.new(x, y, 0, 0)
        index += 1
      end
    end
  end
  
  def needs_cursor?
    return true
  end

  def tile_exists?(x, y)
    return ((x >= 0) and (x < $tileCountW) and (y >= 0) and (y < $tileCountH))
  end

  def update
    if ($animationTimer > 0)
      self.update_animation()
      return
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

    #REACT TO CLICKS
    if self.button_down?(Gosu::MsLeft)
      idx_0 = $mouseBoxY*$tileCountW + $mouseBoxX
      idx_1 = idx_0 + 1
      idx_2 = ($mouseBoxY+1)*$tileCountW + $mouseBoxX
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
      index = 0
      for x in 1..$tileCountW
        for y in 1..$tileCountH
          @tiles[index].endAnimation()
          index += 1
        end
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

  end

  class Tile
    def initialize(x, y, rotation, type)
      @x = x
      @y = y
      
      @xPrev = x
      @yPrev = y

      @rotation = rotation
      @rotationPrev = rotation

      @type = type
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
      dx = (@x-@xPrev) * animationStage
      dy = (@y-@yPrev) * animationStage
      dRot = (@rotation-@rotationPrev) * animationStage

      $tileSprites[0].draw_rot((@xPrev-1+dx) * $tileSize + $tileSize/2 + $innerX, 
                         (@yPrev-1+dy) * $tileSize + $tileSize/2 + $innerY, 
                         $tileZ, (@rotationPrev+dRot)*90, 0.5, 0.5, 
                         $tileScale, $tileScale, 
                         0xff_ffffff, :default)
    end

    def endAnimation()
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


    end
  end
end

GearsGame.new.show
