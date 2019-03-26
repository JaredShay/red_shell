class Input
  UNKNOWN     = :unknown
  UP_ARROW    = :up_arrow
  DOWN_ARROW  = :down_arrow
  LEFT_ARROW  = :left_arrow
  RIGHT_ARROW = :right_arrow
  ESCAPE      = :escape
  A_L         = :a
  B_L         = :b
  C_L         = :c
  D_L         = :d
  E_L         = :e
  F_L         = :f
  G_L         = :g
  H_L         = :h
  I_L         = :i
  J_L         = :j
  K_L         = :k
  L_L         = :l
  M_L         = :m
  N_L         = :n
  O_L         = :o
  P_L         = :p
  Q_L         = :q
  R_L         = :r
  S_L         = :s
  T_L         = :t
  U_L         = :u
  V_L         = :v
  W_L         = :w
  X_L         = :x
  Y_L         = :y
  Z_L         = :z
  A_U         = :A
  B_U         = :B
  C_U         = :C
  D_U         = :D
  E_U         = :E
  F_U         = :F
  G_U         = :G
  H_U         = :H
  I_U         = :I
  J_U         = :J
  K_U         = :K
  L_U         = :L
  M_U         = :M
  N_U         = :N
  O_U         = :O
  P_U         = :P
  Q_U         = :Q
  R_U         = :R
  S_U         = :S
  T_U         = :T
  U_U         = :U
  V_U         = :V
  W_U         = :W
  X_U         = :X
  Y_U         = :Y
  Z_U         = :Z
  ONE         = :one
  TWO         = :two
  THREE       = :three
  FOUR        = :four
  FIVE        = :five
  SIX         = :six
  SEVEN       = :seven
  EIGHT       = :eight
  NINE        = :nine
  LEFT_SQUARE_BRACKET = :left_square_bracket

  KEYS = {
    "\e[A" => UP_ARROW,
    "\e[B" => DOWN_ARROW,
    "\e[C" => RIGHT_ARROW,
    "\e[D" => LEFT_ARROW,
    "\e"   => ESCAPE,
    "a"    => A_L,
    "b"    => B_L,
    "c"    => C_L,
    "d"    => D_L,
    "e"    => E_L,
    "f"    => F_L,
    "g"    => G_L,
    "h"    => H_L,
    "i"    => I_L,
    "j"    => J_L,
    "k"    => K_L,
    "l"    => L_L,
    "m"    => M_L,
    "n"    => N_L,
    "o"    => O_L,
    "p"    => P_L,
    "q"    => Q_L,
    "r"    => R_L,
    "s"    => S_L,
    "t"    => T_L,
    "u"    => U_L,
    "v"    => V_L,
    "w"    => W_L,
    "x"    => X_L,
    "y"    => Y_L,
    "z"    => Z_L,
    "A"    => A_U,
    "B"    => B_U,
    "C"    => C_U,
    "D"    => D_U,
    "E"    => E_U,
    "F"    => F_U,
    "G"    => G_U,
    "H"    => H_U,
    "I"    => I_U,
    "J"    => J_U,
    "K"    => K_U,
    "L"    => L_U,
    "M"    => M_U,
    "N"    => N_U,
    "O"    => O_U,
    "P"    => P_U,
    "Q"    => Q_U,
    "R"    => R_U,
    "S"    => S_U,
    "T"    => T_U,
    "U"    => U_U,
    "V"    => V_U,
    "W"    => W_U,
    "X"    => X_U,
    "Y"    => Y_U,
    "Z"    => Z_U,
    "1"    => ONE,
    "2"    => TWO,
    "3"    => THREE,
    "4"    => FOUR,
    "5"    => FIVE,
    "6"    => SIX,
    "7"    => SEVEN,
    "8"    => EIGHT,
    "9"    => NINE,
    "["    => LEFT_SQUARE_BRACKET
  }

  ESC_SEQUENCE_FINAL_CHARS = ['A', 'B', 'C', 'D']

  def self.poll_start
    set_terminal_options

    @raw_input_queue    = Queue.new
    @parsed_input_queue = Queue.new

    @raw_input_thread = Thread.new do
      begin
        loop do
          c = STDIN.read_nonblock(1) rescue nil

          exit(1) if c == "\u0003"

          @raw_input_queue << c if c
        end
      ensure
        unset_terminal_options
      end
    end

    @parsing_thread = Thread.new do
      char_sequence = ""

      # pop blocks until an item can be dequeued
      while c = @raw_input_queue.pop
        char_sequence, parsed_keys = parse_char(c, char_sequence)

        parsed_keys.each { |k| @parsed_input_queue << k }

        # If there is no current sequence we can go back to waiting for another
        # item to parse.
        #
        # If there is another item to parse we don't need to wait to continue
        # parsing.
        next if char_sequence.empty? || !@raw_input_queue.empty?

        # we are in an ambigous state and don't want to wait for another item
        # to appear in the raw_input_queue as `pop` blocks. Sleep to wait for
        # another item, if no item appears then flush the queue and treat all
        # remaining items as key presses. If an item appears resume parsing.

        # This only works if the sleep interval is greater than the rate at
        # which we can parse key presses.

        sleep 0.01

        if @raw_input_queue.empty?
          char_sequence.split('').each do |char|
            @parsed_input_queue << KEYS[char] || UNKNOWN
          end

          char_sequence = ""
        end
      end
    end

    nil
  end

  # returns "char_sequence", [parsed_keys]
  def self.parse_char(char, char_sequence)
    case char_sequence.length
    when 0
      if char != "\e"
        # if there is no current sequence then all characters that are not "\e"
        # are assumed to be single key presses
        [char_sequence, [KEYS[char] || UNKNOWN]]
      else
        # char is "\e" so it is pushed onto the current sequence to wait for
        # another character to disambiguate.
        [char_sequence << char, []]
      end
    when 1
      if char == "["
        # a sequence of length 1 can only be "\e" so the "[" character may
        # represent either two individual key presses, "\e" and "[", or it may
        # represent an escape sequence.
        [char_sequence << char, []]
      else
        # There is a current sequence and the current char does not indicate it
        # is part of an escape sequence.
        #
        # Parse the first character in the sequence as if it were a single key
        # press and continue to parse the char with an empty sequence.
        key = KEYS[char_sequence] || UNKNOWN

        _char_sequence, _parsed_keys = parse_char(char, "")

        [_char_sequence, [key] + _parsed_keys]
      end
    when 2
      if ESC_SEQUENCE_FINAL_CHARS.include?(char)
        # The final char is part of an escape sequence. Map the entire sequence
        # to a key and return it along with an empty sequence.
        ["", [KEYS[char_sequence << char] || UNKNOWN]]
      else
        # The final char does not make up a complete escape sequence. Map the
        # first two characters in the sequence to single key presses and
        # continue parsing the current char with an empty sequence
        keys = char_sequence.split('').map do |c|
          KEYS[c] || UNKNOWN
        end

        _char_sequence, _parsed_keys = parse_char(char, "")

        [_char_sequence, keys + _parsed_keys]
      end
    end
  end

  def self.poll_stop
    return unless defined?(:@raw_input_thread)

    @raw_input_thread.kill
  end

  private

  def self.set_terminal_options
    # raw   - read characters without using return
    # opost - remove all post processing
    # echo  - don't echo back characters
    system('stty raw opost -echo')
  end

  def self.unset_terminal_options
    system("stty -raw echo")
  end
end
