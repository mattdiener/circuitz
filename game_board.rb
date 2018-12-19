require 'json'
require 'fileutils'

require_relative 'animation_manager'
require_relative 'backboard_square'
require_relative 'game_constants'
require_relative 'game_info'
require_relative 'tile'

# Simply represents the level's basic info (name, next level, etc.)
class Level
  attr_reader :name
  attr_reader :next_level

  def initialize(name, next_level)
    @name = name
    @next_level = next_level
  end
end

# Manages everything to do with the game's board, including size, tiles, and the state of player interaction
# This extends to whether we are in debug mode. It also extends to level saving/loading/information
class GameBoard
  attr_reader :tile_size
  attr_reader :tile_scale
  attr_reader :board_x
  attr_reader :board_y
  attr_reader :game_info
  attr_reader :width
  attr_reader :height

  def initialize(game_info, animation_manager)
    @game_info = game_info
    @animation_manager = animation_manager

    reset_mouse_box
    reset_debug_box
  end

  def set_dimensions(width, height)
    @width = width
    @height = height

    screen_width = @game_info.screen_width
    screen_height = @game_info.screen_height

    max_tile_width = (screen_width-2*MIN_BORDER)/@width
    max_tile_height = (screen_height-2*MIN_BORDER)/@height

    @tile_size = [max_tile_width, max_tile_height].min()

    @border_sides = (screen_width - width*@tile_size)/2
    @border_top_bottom = (screen_height - height*@tile_size)/2

    @board_x = @border_sides
    @board_y = @border_top_bottom

    @tile_scale = @tile_size / TILE_SOURCE_SIZE
  end

  def load_tiles(tiles)
    @tiles = Array.new(@width * @height)
    index = 0
    for y in 0..(@height-1)
      for x in 0..(@width-1)
        @tiles[index] = create_tile(x, y, tiles[index]["rotation"], tiles[index]["type"])
        index += 1
      end
    end
  end

  def load_backboard(backboard)
    @backboard = Array.new(@width * @height)
    index = 0
    for y in 0..(@height-1)
      for x in 0..(@width-1)
        @backboard[index] = create_backboard_square(x, y, backboard[index])
        index += 1
      end
    end
  end

  def floor_to_power_of_two(num)
    return 2**(Math.log2(num).floor())
  end

  def reset_mouse_box
    @player_box_position = Vector2.new(-1, -1)
    @mouse_can_click = false
  end

  def reset_debug_box
    @debug_box_positon = Vector2.new(-1, -1)
  end

  def save_as(name, force)
    level_file = "levels/#{name}.json"

    sav_backboard = Array.new(@width*@height)
    sav_tiles = Array.new(@width*@height)

    index = 0
    for y in 1..(@height)
      for x in 1..(@width)
        sav_tiles[index] = @tiles[index].to_serial
        sav_backboard[index] = @backboard[index].to_serial
        index += 1
      end
    end

    level = {
              'width' => @width,
              'height' => @height,
              'backboard' => sav_backboard,
              'tiles' => sav_tiles,
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

  def send_signal_to_tile(x, y, signal)
    @tiles[tile_index(x, y)].receive_signal(signal) if tile_exists?(x, y)
  end

  def tile_index(x, y)
    return y*@width + x
  end

  def tile_exists?(x, y)
    return @backboard[tile_index(x,y)].exists? if tile_in_range?(x, y)
    return false
  end

  def tile_in_range?(x, y)
    return ((x >= 0) and (x < @width) and (y >= 0) and (y < @height))
  end

  def tile_can_rotate?(x, y)
    if tile_in_range?(x, y)
      return @backboard[tile_index(x,y)].can_rotate?
    end
  end

  def tile_can_swap?(x, y, direction)

  end

  def load_next_level
    load_level(@level.next_level)
  end

  def handle_debug_swap_key(direction)
    return if @animation_manager.is_animating?
    
    tile_index_a = tile_index(@debug_box_positon.x,@debug_box_positon.y)
    tile_index_b = tile_index(@debug_box_positon.x,@debug_box_positon.y)

    case direction
    when :up
      #swap up
      if tile_exists?(@debug_box_positon.x,@debug_box_positon.y) and
         tile_exists?(@debug_box_positon.x,@debug_box_positon.y-1)
        tile_index_b = tile_index(@debug_box_positon.x,@debug_box_positon.y-1)
        @tiles[tile_index_a].debug_translate(:up)
        @tiles[tile_index_b].debug_translate(:down)
        @tiles[tile_index_a], @tiles[tile_index_b] = @tiles[tile_index_b], @tiles[tile_index_a]
        @animation_manager.trigger_animation(TILE_ROTATION_TIME)
      end
    when :left
      #swap left
      if tile_exists?(@debug_box_positon.x,@debug_box_positon.y) and
         tile_exists?(@debug_box_positon.x-1,@debug_box_positon.y)
        tile_index_b = tile_index(@debug_box_positon.x-1,@debug_box_positon.y)
        @tiles[tile_index_a].debug_translate(:left)
        @tiles[tile_index_b].debug_translate(:right)
        @tiles[tile_index_a], @tiles[tile_index_b] = @tiles[tile_index_b], @tiles[tile_index_a]
        @animation_manager.trigger_animation(TILE_ROTATION_TIME)
      end
    when :down
      #swap down
      if tile_exists?(@debug_box_positon.x,@debug_box_positon.y) and
         tile_exists?(@debug_box_positon.x,@debug_box_positon.y+1)
        tile_index_b = tile_index(@debug_box_positon.x,@debug_box_positon.y+1)
        @tiles[tile_index_a].debug_translate(:down)
        @tiles[tile_index_b].debug_translate(:up)
        @tiles[tile_index_a], @tiles[tile_index_b] = @tiles[tile_index_b], @tiles[tile_index_a]
        @animation_manager.trigger_animation(TILE_ROTATION_TIME)
      end
    when :right
      #swap right
      if tile_exists?(@debug_box_positon.x,@debug_box_positon.y) and
         tile_exists?(@debug_box_positon.x+1,@debug_box_positon.y)
        tile_index_b = tile_index(@debug_box_positon.x+1,@debug_box_positon.y)
        @tiles[tile_index_a].debug_translate(:right)
        @tiles[tile_index_b].debug_translate(:left)
        @tiles[tile_index_a], @tiles[tile_index_b] = @tiles[tile_index_b], @tiles[tile_index_a]
        @animation_manager.trigger_animation(TILE_ROTATION_TIME)
      end
    end
  end

  def handle_debug_rotate_key(direction)
    return if @animation_manager.is_animating?

    tile_index = tile_index(@debug_box_positon.x,@debug_box_positon.y)

    if tile_exists?(@debug_box_positon.x,@debug_box_positon.y)
      @tiles[tile_index].debug_rotate(direction)
      @animation_manager.trigger_animation(TILE_ROTATION_TIME)
    end
  end

  def handle_debug_next_backboard
    @backboard[tile_index_a] = @backboard[tile_index_a].create_next_backboard_type()
  end

  def handle_debug_next_tile
    @tiles[tile_index_a] = @tiles[tile_index_a].create_next_tile_type()
  end

  def draw
    draw_tiles
    draw_backboard
    draw_mouse_box
  end

  def draw_tiles
    index = 0
    animation_progress = @animation_manager.progress

    for x in 1..@width
      for y in 1..@height
        @tiles[index].draw(animation_progress)
        index += 1
      end
    end
  end

  def draw_backboard
    index = 0
    for x in 1..@width
      for y in 1..@height
        @backboard[index].draw()
        index += 1
      end
    end
  end

  def draw_mouse_box
    outlineColor = COLOR_WHITE

    if not @mouse_can_click
      outlineColor = COLOR_RED
    end

    #2 vertical lines and 2 horizontal
    if not @game_info.debug_mode
      if (@player_box_position.x < 0 or @player_box_position.y < 0)
        return
      end

      Gosu.draw_rect( @board_x + ((@player_box_position.x+0)*@tile_size) - 1, @board_y + (@player_box_position.y*@tile_size) - 1, 3, @tile_size*2 + 3, outlineColor, Z_GRID)
      Gosu.draw_rect( @board_x + ((@player_box_position.x+2)*@tile_size) - 1, @board_y + (@player_box_position.y*@tile_size) - 1, 3, @tile_size*2 + 3, outlineColor, Z_GRID)
      Gosu.draw_rect( @board_x + (@player_box_position.x*@tile_size) - 1, @board_y + ((@player_box_position.y+0)*@tile_size) - 1, @tile_size*2 + 3, 3, outlineColor, Z_GRID)
      Gosu.draw_rect( @board_x + (@player_box_position.x*@tile_size) - 1, @board_y + ((@player_box_position.y+2)*@tile_size) - 1, @tile_size*2 + 3, 3, outlineColor, Z_GRID)
    else
      if (@debug_box_positon.x < 0 or @debug_box_positon.y < 0)
        return
      end

      debugColor = Gosu::Color::GREEN

      Gosu.draw_rect(@board_x + ((@debug_box_positon.x+0)*@tile_size) - 1, @board_y + (@debug_box_positon.y*@tile_size) - 1, 3, @tile_size + 3, debugColor, Z_GRID)
      Gosu.draw_rect(@board_x + ((@debug_box_positon.x+1)*@tile_size) - 1, @board_y + (@debug_box_positon.y*@tile_size) - 1, 3, @tile_size + 3, debugColor, Z_GRID)
      Gosu.draw_rect(@board_x + (@debug_box_positon.x*@tile_size) - 1, @board_y + ((@debug_box_positon.y+0)*@tile_size) - 1, @tile_size + 3, 3, debugColor, Z_GRID)
      Gosu.draw_rect(@board_x + (@debug_box_positon.x*@tile_size) - 1, @board_y + ((@debug_box_positon.y+1)*@tile_size) - 1, @tile_size + 3, 3, debugColor, Z_GRID)
    end
  end

  def end_animation
    index = 0
    for x in 1..@width
      for y in 1..@height
        @tiles[index].end_animation()
        index += 1
      end
    end

    index = 0
    for x in 1..@width
      for y in 1..@height
        @tiles[index].receive_signal(:on)
        index += 1
      end
    end
  end

  def level_done?
    level_done = true
    index = 0
    for y in 0..(@height-1)
      for x in 0..(@width-1)
        level_done = false if not @tiles[index].condition_satisfied?
        index += 1
      end
    end

    return level_done
  end

  def update_mouse_boxes(mouse_x, mouse_y)
    update_player_box(mouse_x, mouse_y)
    update_debug_box(mouse_x, mouse_y)
  end

  def update_player_box(mouse_x, mouse_y)
    tmp_player_box_x = @player_box_position.x
    tmp_player_box_y = @player_box_position.y

    if mouse_x > @board_x and mouse_x <= (@board_x + (@tile_size * @width))
      tmp_player_box_x = (mouse_x - @border_sides).div(@tile_size)
    else
      tmp_player_box_x = -1
    end

    if mouse_y > @board_y and mouse_y <= (@board_y + (@tile_size * @height))
      tmp_player_box_y = (mouse_y - @border_top_bottom).div(@tile_size)
    else
      tmp_player_box_y = -1
    end

    mouse_moved = false

    # we use the following priority for mouse selection:
    # => 1) top left corner
    # => 2) top right corner
    # => 3) bottom left corner
    # => 4) bottom right corner
    if player_box_is_selectable?(tmp_player_box_x, tmp_player_box_y)
      mouse_moved = true
    elsif player_box_is_selectable?(tmp_player_box_x-1, tmp_player_box_y)
      tmp_player_box_x -= 1
      mouse_moved = true
    elsif player_box_is_selectable?(tmp_player_box_x, tmp_player_box_y-1)
      tmp_player_box_y -= 1
      mouse_moved = true
    elsif player_box_is_selectable?(tmp_player_box_x-1, tmp_player_box_y-1)
      tmp_player_box_x -= 1
      tmp_player_box_y -= 1
      mouse_moved = true
    end

    if mouse_moved
      @mouse_can_click = false  
      @player_box_position = Vector2.new(tmp_player_box_x, tmp_player_box_y)
    end

    if player_box_can_rotate?(tmp_player_box_x, tmp_player_box_y)
      @mouse_can_click = true
    end
  end

  def player_box_is_selectable?(box_x, box_y)
    return (tile_exists?(box_x    , box_y)     and
            tile_exists?(box_x + 1, box_y)     and
            tile_exists?(box_x    , box_y + 1) and
            tile_exists?(box_x + 1, box_y + 1))
  end

  def player_box_can_rotate?(box_x, box_y)
    return (tile_can_rotate?(box_x    , box_y)     and
            tile_can_rotate?(box_x + 1, box_y)     and
            tile_can_rotate?(box_x    , box_y + 1) and
            tile_can_rotate?(box_x + 1, box_y + 1))
  end

  def update_debug_box(mouse_x, mouse_y)
    tmp_debug_box_x = @player_box_position.x
    tmp_debug_box_y = @player_box_position.y

    if mouse_x > @board_x and mouse_x <= (@board_x + (@tile_size * @width))
      tmp_debug_box_x = (mouse_x - @border_sides).div(@tile_size)
    else
      tmp_debug_box_x = -1
    end

    if mouse_y > @board_y and mouse_y <= (@board_y + (@tile_size * @height))
      tmp_debug_box_y = (mouse_y - @border_top_bottom).div(@tile_size)
    else
      tmp_debug_box_y = -1
    end

    if tile_exists?(tmp_debug_box_x, tmp_debug_box_y)
      @debug_box_positon = Vector2.new(tmp_debug_box_x, tmp_debug_box_y)
    end
  end

  def debug_resize(direction)
    height_new = @height
    width_new = @width

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

    xMax = [width_new, @width].min() - 1
    yMax = [height_new, @height].min() - 1
    
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

  def handle_left_click
    return if not @mouse_can_click
    return if @animation_manager.is_animating?

    idx_0 = tile_index(@player_box_position.x, @player_box_position.y)
    idx_1 = idx_0 + 1
    idx_2 = tile_index(@player_box_position.x, @player_box_position.y+1)
    idx_3 = idx_2 + 1

    @tiles[idx_0].rotate_in_box(1, 0)
    @tiles[idx_1].rotate_in_box(1, 1)
    @tiles[idx_2].rotate_in_box(1, 2)
    @tiles[idx_3].rotate_in_box(1, 3)

    #We want to swap their indeces so we can continue to use the array to find the tiles properly
    tmp = @tiles[idx_0]
    @tiles[idx_0] = @tiles[idx_2]
    @tiles[idx_2] = @tiles[idx_3]
    @tiles[idx_3] = @tiles[idx_1]
    @tiles[idx_1] = tmp

    @animation_manager.trigger_animation(TILE_ROTATION_TIME)
  end

  def handle_right_click
    return if not @mouse_can_click
    return if @animation_manager.is_animating?

    idx_0 = tile_index(@player_box_position.x, @player_box_position.y)
    idx_1 = idx_0 + 1
    idx_2 = tile_index(@player_box_position.x, @player_box_position.y+1)
    idx_3 = idx_2 + 1

    @tiles[idx_0].rotate_in_box(-1, 0)
    @tiles[idx_1].rotate_in_box(-1, 1)
    @tiles[idx_2].rotate_in_box(-1, 2)
    @tiles[idx_3].rotate_in_box(-1, 3)

    #We want to swap their indeces so we can continue to use the array to find the tiles properly
    tmp = @tiles[idx_0]
    @tiles[idx_0] = @tiles[idx_1]
    @tiles[idx_1] = @tiles[idx_3]
    @tiles[idx_3] = @tiles[idx_2]
    @tiles[idx_2] = tmp

    @animation_manager.trigger_animation(TILE_ROTATION_TIME)
  end

  def create_tile(x, y, rotation, type)
    case type
    when "s"
      return SourceTile.new(x,y,rotation,self)
    when "k"
      return SinkTile.new(x,y,rotation,self)
    when "c"
      return CornerTile.new(x,y,rotation,self)
    when "l"
      return StraightTile.new(x,y,rotation,self)
    when "L"
      return OverUnderTile.new(x,y,rotation,self)
    when "C"
      return DoubleCornerTile.new(x,y,rotation,self)
    when "n"
      return NoTile.new(x,y,rotation,self)
    else
      return NoTile.new(x,y,rotation,self)
    end
  end

  def create_backboard_square(x, y, type)
    case type
    when "d"
      return BackboardSquare.new(x,y,self)
    when "s"
      return StaticBackboardSquare.new(x,y,self)
    when "n"
      return NoBackboardSquare.new(x,y,self)
    else
      return NoBackboardSquare.new(x,y,self)
    end
  end

  def load_level(name)
    return if not name or name == ''

    level_string = File.read(File.join("levels", name + ".json"))
    level_contents = JSON.parse(level_string)

    set_dimensions(level_contents["width"], level_contents["height"])
    load_backboard(level_contents["backboard"])
    load_tiles(level_contents["tiles"])

    @level = Level.new(name, level_contents["next_level"])

    reset_mouse_box()

    @game_info.state = :fade_in
    @animation_manager.trigger_animation(FADE_TIME)
  end
end