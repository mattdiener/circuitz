require 'gosu'

class BackboardSquare
  def initialize(x, y, game_board)
    @x = x
    @y = y
    @game_board = game_board
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
    return COLOR_BEIGE
  end

  def draw
    # BOX
    Gosu.draw_rect(@game_board.board_x + @x * @game_board.tile_size, 
                   @game_board.board_y + @y * @game_board.tile_size, 
                   @game_board.tile_size, @game_board.tile_size, 
                   color(), Z_BG)

    # LINES
    lineColor = COLOR_COFFEE

    # draw vertical lines
    Gosu.draw_rect(@game_board.board_x + (@x * @game_board.tile_size) - 1, 
                   @game_board.board_y + (@y * @game_board.tile_size) - 1, 
                   3, @game_board.tile_size + 3, lineColor, Z_GRID)

    Gosu.draw_rect(@game_board.board_x + ((@x+1) * @game_board.tile_size) - 1, 
                   @game_board.board_y + ( @y    * @game_board.tile_size) - 1, 
                   3, @game_board.tile_size + 3, lineColor, Z_GRID)

    # draw horizontal lines
    Gosu.draw_rect(@game_board.board_x + (@x * @game_board.tile_size) - 1, 
                   @game_board.board_y + (@y * @game_board.tile_size) - 1, 
                   @game_board.tile_size + 3, 3, lineColor, Z_GRID)

    Gosu.draw_rect(@game_board.board_x + ( @x    * @game_board.tile_size) - 1, 
                   @game_board.board_y + ((@y+1) * @game_board.tile_size) - 1, 
                   @game_board.tile_size + 3, 3, lineColor, Z_GRID)
  end

  def create_next_backboard_type()
    return StaticBackboardSquare.new(@x, @y)
  end
end

class StaticBackboardSquare < BackboardSquare
  def initialize(x, y, game_board)
    super(x, y, game_board)
  end

  def to_serial
    return 's'
  end

  def can_rotate?
    return false
  end

  def color
    return COLOR_BROWN
  end

  def create_next_backboard_type()
    return NoBackboardSquare.new(@x, @y)
  end
end

class NoBackboardSquare < StaticBackboardSquare
  def initialize(x, y, game_board)
    super(x, y, game_board)
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