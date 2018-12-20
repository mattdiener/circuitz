require 'gosu'

#CONSTS
TILE_SOURCE_SIZE = 16
TILE_SPRITES = *Gosu::Image.load_tiles("./assets/puzzletiles.png", TILE_SOURCE_SIZE, TILE_SOURCE_SIZE, {retro: true})
TILE_ROTATION_TIME = 16

#TILE TYPES
class Tile
  def initialize(x, y, rotation, game_board)
    @game_board = game_board

    @x = x
    @y = y
    
    @x_prev = x
    @y_prev = y

    @rotation = rotation
    @rotation_prev = rotation

    @sprite_index = 0
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

  def rotate_in_box(direction, box_position)
    @rotation += direction
    
    if (box_position == 0)
      if (direction == 1)
        @x += 1
      elsif (direction == -1)
        @y += 1
      end
    elsif (box_position == 1)
      if (direction == 1)
        @y += 1
      elsif (direction == -1)
        @x -= 1
      end
    elsif (box_position == 2)
      if (direction == 1)
        @y -= 1
      elsif (direction == -1)
        @x += 1
      end
    elsif (box_position == 3)
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

    dx = (@x-@x_prev) * animationStage
    dy = (@y-@y_prev) * animationStage
    d_rot = (@rotation-@rotation_prev) * animationStage

    TILE_SPRITES[@sprite_index].draw_rot((@x_prev+dx) * @game_board.tile_size + @game_board.tile_size/2 + @game_board.board_x, 
                                         (@y_prev+dy) * @game_board.tile_size + @game_board.tile_size/2 + @game_board.board_y, 
                                         Z_TILE, (@rotation_prev + d_rot)*90, 0.5, 0.5, 
                                         @game_board.tile_scale, @game_board.tile_scale, 
                                         0xff_ffffff, :default)

    game_info = @game_board.game_info

    if game_info.show_rotations
       game_info.default_font.draw_text_rel(@rotation.to_s, 
                         @x*@game_board.tile_size + @game_board.tile_size/2 + @game_board.board_x, 
                         @y*@game_board.tile_size + @game_board.tile_size/2 + @game_board.board_y, 
                         Z_TILE, 0.5, 0.5, @game_board.tile_scale/2, @game_board.tile_scale/2, Gosu::Color::BLUE)
    end
  end

  def end_animation()
    @x_prev = @x
    @y_prev = @y

    #normalize the rotations so we can have regular numbers for game logic
    while @rotation >= 4
      @rotation -= 4
    end

    while @rotation <= -1
      @rotation += 4
    end

    @rotation_prev = @rotation

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

    @game_board.send_signal_to_tile(dest_x, dest_y, dest_side)
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
    return NoTile.new(@x, @y, @rotation, @game_board)
  end
end

class NoTile < Tile
  def draw(animation_stage)
    #noop
  end

  def type_letter
    return 'n'
  end

  def create_next_tile_type()
    return SourceTile.new(@x, @y, @rotation, @game_board)
  end
end

class SourceTile < Tile
  def initialize(x, y, rotation, game_board)
    super(x, y, rotation, game_board)

    @is_on = false
    @off_index = 0
    @on_index = 1
  end
  
  def type_letter
    return 's'
  end

  def reset_signal()
    @is_on = false
  end

  def receive_signal(side)
    if side == :on and not @is_on
      @is_on = true

      if (@rotation == ROTATION_DOWN)
        send_signal(:down)
      elsif (@rotation == ROTATION_LEFT)
        send_signal(:left)
      elsif (@rotation == ROTATION_UP)
        send_signal(:up)
      elsif (@rotation == ROTATION_RIGHT)
        send_signal(:right)
      end
    end
  end

  def refresh_sprite_index()
    if @is_on
      @sprite_index = @on_index
    else
      @sprite_index = @off_index
    end
  end

  def create_next_tile_type()
    return CornerTile.new(@x, @y, @rotation, @game_board)
  end
end

class CornerTile < Tile
  def initialize(x, y, rotation, game_board)
    super(x, y, rotation, game_board)

    @is_on = false
    @off_index = 4
    @on_index = 5
  end

  def type_letter
    return 'c'
  end
  
  def reset_signal()
    @is_on = false
  end

  def in_signal_to_out_signal(side)
    out = :none

    case @rotation
    when ROTATION_DOWN
      if side == :down
        out = :right
      end
      if side == :right
        out = :down
      end
    when ROTATION_LEFT
      if side == :down
        out = :left
      end
      if side == :left
        out = :down
      end
    when ROTATION_UP
      if side == :left
        out = :up
      end
      if side == :up
        out = :left
      end
    when ROTATION_RIGHT
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

    if not @is_on and out_side != :none
      @is_on = true
      send_signal(out_side)
    end
  end

  def refresh_sprite_index()
    if @is_on
      @sprite_index = @on_index
    else
      @sprite_index = @off_index
    end
  end

  def create_next_tile_type()
    return StraightTile.new(@x, @y, @rotation, @game_board)
  end
end

class StraightTile < Tile
  def initialize(x, y, rotation, game_board)
    super(x, y, rotation, game_board)

    @is_on = false
    @off_index = 6
    @on_index = 7
  end
  
  def type_letter
    return 'l'
  end

  def reset_signal()
    @is_on = false
  end

  def in_signal_to_out_signal(side)
    out = :none

    case @rotation
    when ROTATION_DOWN, ROTATION_UP
      if side == :down
        out = :up
      end
      if side == :up
        out = :down
      end
    when ROTATION_LEFT, ROTATION_RIGHT
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

    if not @is_on and out_side != :none
      @is_on = true
      send_signal(out_side)
    end
  end

  def refresh_sprite_index()
    if @is_on
      @sprite_index = @on_index
    else
      @sprite_index = @off_index
    end
  end

  def create_next_tile_type()
    return OverUnderTile.new(@x, @y, @rotation, @game_board)
  end
end

class OverUnderTile < Tile
  def initialize(x, y, rotation, game_board)
    super(x, y, rotation, game_board)

    @is_on_over = false
    @is_on_under = false

    @off_index = 8
    @on_over_index = 9
    @on_under_index = 10
    @on_index = 11
  end
  
  def type_letter
    return 'L'
  end

  def reset_signal()
    @is_on_over = false
    @is_on_under = false
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
    when ROTATION_UP, ROTATION_DOWN
      if (out_side == :up or out_side == :down) and not @is_on_under
        @is_on_under = true
        send_signal(out_side)
      elsif (out_side == :left or out_side == :right) and not @is_on_over
        @is_on_over = true
        send_signal(out_side)
      end 
    when ROTATION_LEFT, ROTATION_RIGHT
      if (out_side == :up or out_side == :down) and not @is_on_over
        @is_on_over = true
        send_signal(out_side)
      elsif (out_side == :left or out_side == :right) and not @is_on_under
        @is_on_under = true
        send_signal(out_side)
      end 
    end
  end

  def refresh_sprite_index()
    if @is_on_over and @is_on_under
      @sprite_index = @on_index
    elsif @is_on_over
      @sprite_index = @on_over_index
    elsif @is_on_under
      @sprite_index = @on_under_index
    else
      @sprite_index = @off_index
    end
  end

  def create_next_tile_type()
    return DoubleCornerTile.new(@x, @y, @rotation, @game_board)
  end
end

class DoubleCornerTile < Tile
  def initialize(x, y, rotation, game_board)
    super(x, y, rotation, game_board)

    @is_on_a = false #down-right
    @is_on_b = false #up-left

    @off_index = 12
    @onAIndex = 13
    @onBIndex = 14
    @on_index = 15
  end
  
  def type_letter
    return 'C'
  end

  def reset_signal()
    @is_on_a = false
    @is_on_b = false
  end

  def in_signal_to_out_signal(side)
    case @rotation
    when ROTATION_UP, ROTATION_DOWN
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
    when ROTATION_LEFT, ROTATION_RIGHT
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
    when ROTATION_DOWN
      if (out_side == :down or out_side == :right) and not @is_on_a
        @is_on_a = true
        send_signal(out_side)
      elsif (out_side == :up or out_side == :left) and not @is_on_b
        @is_on_b = true
        send_signal(out_side)
      end 
    when ROTATION_LEFT
      if (out_side == :down or out_side == :left) and not @is_on_a
        @is_on_a = true
        send_signal(out_side)
      elsif (out_side == :up or out_side == :right) and not @is_on_b
        @is_on_b = true
        send_signal(out_side)
      end 
    when ROTATION_UP
      if (out_side == :up or out_side == :left) and not @is_on_a
        @is_on_a = true
        send_signal(out_side)
      elsif (out_side == :down or out_side == :right) and not @is_on_b
        @is_on_b = true
        send_signal(out_side)
      end 
    when ROTATION_RIGHT
      if (out_side == :up or out_side == :right) and not @is_on_a
        @is_on_a = true
        send_signal(out_side)
      elsif (out_side == :down or out_side == :left) and not @is_on_b
        @is_on_b = true
        send_signal(out_side)
      end 
    end
  end

  def refresh_sprite_index()
    if @is_on_a and @is_on_b
      @sprite_index = @on_index
    elsif @is_on_a
      @sprite_index = @onAIndex
    elsif @is_on_b
      @sprite_index = @onBIndex
    else
      @sprite_index = @off_index
    end
  end

  def create_next_tile_type()
    return SinkTile.new(@x, @y, @rotation, @game_board)
  end
end

class SinkTile < Tile
  def initialize(x, y, rotation, game_board)
    super(x, y, rotation, game_board)

    @is_on = false
    @off_index = 2
    @on_index = 3
  end

  def type_letter
    return 'k'
  end
  
  def reset_signal()
    @is_on = false
  end

  def receive_signal(side)
    if side == :down and @rotation == ROTATION_DOWN
      @is_on = true
    elsif side == :left and @rotation == ROTATION_LEFT
      @is_on = true
    elsif side == :up and @rotation == ROTATION_UP
      @is_on = true
    elsif side == :right and @rotation == ROTATION_RIGHT
      @is_on = true
    end
  end

  def refresh_sprite_index()
    if @is_on
      @sprite_index = @on_index
    else
      @sprite_index = @off_index
    end
  end

  def condition_satisfied?()
    return @is_on
  end

  def create_next_tile_type()
    return NoTile.new(@x, @y, @rotation, @game_board)
  end
end