# frozen_string_literal: true

# chess.rb
require 'yaml'
require 'json'

# Piece base class and specific piece implementations
class Piece
  attr_reader :color, :symbol
  attr_accessor :position, :moved

  def initialize(color, position)
    @color = color
    @position = position
    @moved = false
  end

  def valid_moves(_board)
    # To be implemented by subclasses
    []
  end

  def to_s
    @symbol
  end

  def opponent_color
    @color == :white ? :black : :white
  end

  def move(to_position)
    @position = to_position
    @moved = true
  end

  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end

class Pawn < Piece # rubocop:disable Style/Documentation
  def initialize(color, position)
    super
    @symbol = color == :white ? '♙' : '♟'
  end

  def valid_moves(board) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
    moves = []
    direction = @color == :white ? -1 : 1
    start_row = @color == :white ? 6 : 1

    # Forward move
    one_forward = [@position[0] + direction, @position[1]]
    if board.empty?(one_forward)
      moves << one_forward

      # Double move from starting position
      two_forward = [@position[0] + 2 * direction, @position[1]]
      moves << two_forward if @position[0] == start_row && board.empty?(two_forward)
    end

    # Capture moves
    [[direction, -1], [direction, 1]].each do |d_row, d_col|
      capture_pos = [@position[0] + d_row, @position[1] + d_col]
      next unless board.valid_position?(capture_pos) &&
                  !board.empty?(capture_pos) &&
                  board.piece_at(capture_pos).color == opponent_color

      moves << capture_pos
    end

    moves.select { |pos| board.valid_position?(pos) }
  end
end

class Rook < Piece # rubocop:disable Style/Documentation
  def initialize(color, position)
    super
    @symbol = color == :white ? '♖' : '♜'
  end

  def valid_moves(board)
    horizontal_vertical_moves(board)
  end

  private

  def horizontal_vertical_moves(board) # rubocop:disable Metrics/MethodLength
    moves = []
    directions = [[0, 1], [1, 0], [0, -1], [-1, 0]] # right, down, left, up

    directions.each do |d_row, d_col|
      row, col = @position
      loop do
        row += d_row
        col += d_col
        pos = [row, col]

        break unless board.valid_position?(pos)

        if board.empty?(pos)
          moves << pos
        else
          moves << pos if board.piece_at(pos).color == opponent_color
          break
        end
      end
    end

    moves
  end
end

class Knight < Piece # rubocop:disable Style/Documentation
  def initialize(color, position)
    super
    @symbol = color == :white ? '♘' : '♞'
  end

  def valid_moves(board) # rubocop:disable Metrics/MethodLength
    moves = []
    knight_moves = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1]
    ]

    knight_moves.each do |d_row, d_col|
      pos = [@position[0] + d_row, @position[1] + d_col]
      next unless board.valid_position?(pos)

      moves << pos if board.empty?(pos) || board.piece_at(pos).color == opponent_color
    end

    moves
  end
end

class Bishop < Piece # rubocop:disable Style/Documentation
  def initialize(color, position)
    super
    @symbol = color == :white ? '♗' : '♝'
  end

  def valid_moves(board)
    diagonal_moves(board)
  end

  private

  def diagonal_moves(board) # rubocop:disable Metrics/MethodLength
    moves = []
    directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]] # up-left, up-right, down-left, down-right

    directions.each do |d_row, d_col|
      row, col = @position
      loop do
        row += d_row
        col += d_col
        pos = [row, col]

        break unless board.valid_position?(pos)

        if board.empty?(pos)
          moves << pos
        else
          moves << pos if board.piece_at(pos).color == opponent_color
          break
        end
      end
    end

    moves
  end
end

class Queen < Piece # rubocop:disable Style/Documentation
  def initialize(color, position)
    super
    @symbol = color == :white ? '♕' : '♛'
  end

  def valid_moves(board)
    horizontal_vertical_moves(board) + diagonal_moves(board)
  end

  private

  def horizontal_vertical_moves(board) # rubocop:disable Metrics/MethodLength
    moves = []
    directions = [[0, 1], [1, 0], [0, -1], [-1, 0]] # right, down, left, up

    directions.each do |d_row, d_col|
      row, col = @position
      loop do
        row += d_row
        col += d_col
        pos = [row, col]

        break unless board.valid_position?(pos)

        if board.empty?(pos)
          moves << pos
        else
          moves << pos if board.piece_at(pos).color == opponent_color
          break
        end
      end
    end

    moves
  end

  def diagonal_moves(board) # rubocop:disable Metrics/MethodLength
    moves = []
    directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]] # up-left, up-right, down-left, down-right

    directions.each do |d_row, d_col|
      row, col = @position
      loop do
        row += d_row
        col += d_col
        pos = [row, col]

        break unless board.valid_position?(pos)

        if board.empty?(pos)
          moves << pos
        else
          moves << pos if board.piece_at(pos).color == opponent_color
          break
        end
      end
    end

    moves
  end
end

class King < Piece # rubocop:disable Style/Documentation
  def initialize(color, position)
    super
    @symbol = color == :white ? '♔' : '♚'
  end

  def valid_moves(board) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
    moves = []
    king_moves = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1], [1, 0], [1, 1]
    ]

    king_moves.each do |d_row, d_col|
      pos = [@position[0] + d_row, @position[1] + d_col]
      next unless board.valid_position?(pos)

      moves << pos if board.empty?(pos) || board.piece_at(pos).color == opponent_color
    end

    # Castling
    unless @moved
      # Kingside castling
      moves << [@position[0], @position[1] + 2] if can_castle_kingside?(board)

      # Queenside castling
      moves << [@position[0], @position[1] - 2] if can_castle_queenside?(board)
    end

    moves
  end

  private

  def can_castle_kingside?(board) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return false if @moved

    rook_pos = [@position[0], 7]
    return false unless board.valid_position?(rook_pos)

    rook = board.piece_at(rook_pos)
    return false unless rook.is_a?(Rook) && !rook.moved

    # Check if squares between king and rook are empty
    (1..2).each do |offset|
      pos = [@position[0], @position[1] + offset]
      return false unless board.empty?(pos)
    end

    # Check if king is in check
    return false if board.in_check?(@color)

    # Check if king would pass through check
    [1, 2].each do |offset|
      test_pos = [@position[0], @position[1] + offset]
      # Create a temporary board to test if the king would be in check
      temp_board = board.deep_copy
      temp_king = temp_board.piece_at(@position)
      temp_board.grid[@position[0]][@position[1]] = nil
      temp_board.grid[test_pos[0]][test_pos[1]] = temp_king
      return false if temp_board.in_check?(@color)
    end

    true
  end

  def can_castle_queenside?(board) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    return false if @moved

    rook_pos = [@position[0], 0]
    return false unless board.valid_position?(rook_pos)

    rook = board.piece_at(rook_pos)
    return false unless rook.is_a?(Rook) && !rook.moved

    # Check if squares between king and rook are empty
    (1..3).each do |offset|
      pos = [@position[0], @position[1] - offset]
      return false unless board.empty?(pos)
    end

    # Check if king is in check
    return false if board.in_check?(@color)

    # Check if king would pass through check
    [1, 2].each do |offset|
      test_pos = [@position[0], @position[1] - offset]
      # Create a temporary board to test if the king would be in check
      temp_board = board.deep_copy
      temp_king = temp_board.piece_at(@position)
      temp_board.grid[@position[0]][@position[1]] = nil
      temp_board.grid[test_pos[0]][test_pos[1]] = temp_king
      return false if temp_board.in_check?(@color)
    end

    true
  end
end

# ... (the rest of the code remains the same)

# Board class to manage the chess board
class Board # rubocop:disable Metrics/ClassLength
  attr_reader :grid

  def initialize
    @grid = Array.new(8) { Array.new(8, nil) }
    setup_pieces
  end

  def setup_pieces # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # Set up pawns
    (0..7).each do |col|
      @grid[1][col] = Pawn.new(:black, [1, col])
      @grid[6][col] = Pawn.new(:white, [6, col])
    end

    # Set up other pieces
    back_row = %i[black white]
    rows = [0, 7]

    back_row.each_with_index do |color, idx|
      row = rows[idx]

      @grid[row][0] = Rook.new(color, [row, 0])
      @grid[row][1] = Knight.new(color, [row, 1])
      @grid[row][2] = Bishop.new(color, [row, 2])
      @grid[row][3] = Queen.new(color, [row, 3])
      @grid[row][4] = King.new(color, [row, 4])
      @grid[row][5] = Bishop.new(color, [row, 5])
      @grid[row][6] = Knight.new(color, [row, 6])
      @grid[row][7] = Rook.new(color, [row, 7])
    end
  end

  def piece_at(position)
    row, col = position
    @grid[row][col]
  end

  def empty?(position)
    row, col = position
    @grid[row][col].nil?
  end

  def valid_position?(position)
    row, col = position
    row.between?(0, 7) && col.between?(0, 7)
  end

  def move_piece(from, to) # rubocop:disable Metrics/AbcSize
    piece = piece_at(from)
    return false unless piece && valid_position?(to)

    # Handle castling
    if piece.is_a?(King) && (to[1] - from[1]).abs == 2
      perform_castling(from, to)
      return true
    end

    @grid[to[0]][to[1]] = piece
    @grid[from[0]][from[1]] = nil
    piece.move(to)
    true
  end

  def perform_castling(from, to) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    king = piece_at(from)
    direction = to[1] > from[1] ? 1 : -1

    # Move king
    @grid[from[0]][from[1]] = nil
    @grid[to[0]][to[1]] = king
    king.move(to)

    # Move rook
    rook_col = direction == 1 ? 7 : 0
    new_rook_col = to[1] - direction
    rook = piece_at([from[0], rook_col])

    @grid[from[0]][rook_col] = nil
    @grid[from[0]][new_rook_col] = rook
    rook.move([from[0], new_rook_col])
  end

  def in_check?(color)
    king_position = find_king(color)
    return false unless king_position

    opponent_color = color == :white ? :black : :white

    # Check if any opponent piece can capture the king
    @grid.flatten.compact.each do |piece|
      next unless piece.color == opponent_color

      return true if piece.valid_moves(self).include?(king_position)
    end

    false
  end

  def would_be_in_check?(color, from, to)
    # Create a deep copy of the board to test the move
    test_board = Marshal.load(Marshal.dump(self))
    test_board.move_piece(from, to)
    test_board.in_check?(color)
  end

  def find_king(color)
    @grid.each_with_index do |row, i|
      row.each_with_index do |piece, j|
        return [i, j] if piece.is_a?(King) && piece.color == color
      end
    end
    nil
  end

  def checkmate?(color)
    return false unless in_check?(color)

    # If any piece of the given color can make a move that gets out of check
    @grid.flatten.compact.each do |piece|
      next unless piece.color == color

      piece.valid_moves(self).each do |move|
        test_board = Marshal.load(Marshal.dump(self))
        test_board.move_piece(piece.position, move)
        return false unless test_board.in_check?(color)
      end
    end

    true
  end

  def stalemate?(color)
    return false if in_check?(color)

    # If no legal moves but not in check
    @grid.flatten.compact.each do |piece|
      next unless piece.color == color

      piece.valid_moves(self).each do |move|
        test_board = Marshal.load(Marshal.dump(self))
        test_board.move_piece(piece.position, move)
        return false unless test_board.in_check?(color)
      end
    end

    true
  end

  def to_s
    board_str = "  a b c d e f g h\n"
    @grid.each_with_index do |row, i|
      board_str += "#{8 - i} "
      row.each do |piece|
        board_str += piece ? "#{piece} " : '. '
      end
      board_str += "#{8 - i}\n"
    end
    "#{board_str}  a b c d e f g h"
  end

  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end

# Game class to manage the game flow
class ChessGame
  attr_reader :board, :current_player

  def initialize
    @board = Board.new
    @current_player = :white
    @game_over = false
  end

  def play # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    until @game_over
      system('clear') || system('cls')
      puts @board
      puts "#{@current_player.capitalize}'s turn"

      puts 'CHECK!' if @board.in_check?(@current_player)

      move = get_move

      if move == :save
        save_game
        next
      elsif move == :quit
        puts 'Game saved and quit.'
        return
      end

      from, to = move

      if valid_move?(from, to)
        @board.move_piece(from, to)

        if @board.checkmate?(@current_player)
          system('clear') || system('cls')
          puts @board
          puts "Checkmate! #{@current_player.capitalize} wins!"
          @game_over = true
        elsif @board.stalemate?(@current_player)
          system('clear') || system('cls')
          puts @board
          puts 'Stalemate! The game is a draw.'
          @game_over = true
        else
          switch_player
        end
      else
        puts 'Invalid move. Try again.'
        sleep(1)
      end
    end
  end

  def get_move # rubocop:disable Metrics/AbcSize,Naming/AccessorMethodName
    puts "Enter your move (e.g., 'e2 e4'), 'save' to save game, or 'quit' to quit:"
    input = gets.chomp.downcase

    return :save if input == 'save'
    return :quit if input == 'quit'

    from_str, to_str = input.split
    return nil unless from_str && to_str && from_str.length == 2 && to_str.length == 2

    from = [8 - from_str[1].to_i, from_str[0].ord - 'a'.ord]
    to = [8 - to_str[1].to_i, to_str[0].ord - 'a'.ord]

    [from, to]
  end

  def valid_move?(from, to)
    return false unless @board.valid_position?(from) && @board.valid_position?(to)

    piece = @board.piece_at(from)
    return false unless piece && piece.color == @current_player

    return false unless piece.valid_moves(@board).include?(to)

    # Check if move would put or leave king in check
    !@board.would_be_in_check?(@current_player, from, to)
  end

  def switch_player
    @current_player = @current_player == :white ? :black : :white
  end

  def save_game # rubocop:disable Metrics/MethodLength
    puts 'Enter filename to save game:'
    filename = gets.chomp
    filename += '.yaml' unless filename.end_with?('.yaml')

    data = {
      board: @board,
      current_player: @current_player
    }

    File.open(filename, 'w') do |file|
      file.write(YAML.dump(data))
    end

    puts "Game saved to #{filename}"
  end

  def self.load_game # rubocop:disable Metrics/MethodLength
    puts 'Enter filename to load game:'
    filename = gets.chomp
    filename += '.yaml' unless filename.end_with?('.yaml')

    if File.exist?(filename)
      data = YAML.load_file(filename)
      game = ChessGame.new
      game.instance_variable_set(:@board, data[:board])
      game.instance_variable_set(:@current_player, data[:current_player])
      game
    else
      puts 'File not found.'
      nil
    end
  end
end

# Main program
if __FILE__ == $PROGRAM_NAME
  puts 'Welcome to Chess!'
  puts 'Would you like to (1) start a new game or (2) load a saved game?'
  choice = gets.chomp.to_i

  game = if choice == 2
           ChessGame.load_game
         else
           ChessGame.new
         end

  game&.play
end
