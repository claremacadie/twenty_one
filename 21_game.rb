# 21_game.rb

module Formattable
  def clear
    system('clear')
  end

  def blank_line
    puts
  end

  def single_line
    puts "------------"
  end

  def double_line
    puts "============"
  end

  def joinor(arr, delimiter=', ', word='and')
    case arr.size
    when 0 then ''
    when 1 then arr.first
    when 2 then arr.join(" #{word} ")
    else
      arr[-1] = "#{word} #{arr.last}"
      arr.join(delimiter)
    end
  end
end

module Questionable
  include Formattable

  YES_NO_OPTIONS = %w(y yes n no)

  def ask_yes_no_question(question)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.downcase.strip
      break if YES_NO_OPTIONS.include? answer
      puts "Sorry, must be y or n."
      blank_line
    end
    answer[0] == 'y'
  end

  def ask_open_question(question, void_answer)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.strip
      break unless answer.empty? || answer == void_answer
      puts "Sorry, must enter a value (it can't be '#{void_answer}'!)."
      blank_line
    end
    answer
  end

  def ask_closed_question(question, options)
    downcase_options = options.map(&:downcase)
    answer = nil
    loop do
      puts question
      answer = gets.chomp.downcase.strip
      break if downcase_options.include?(answer)
      puts "Sorry, invalid choice."
      blank_line
    end
    answer
  end
end

module Displayable
  include Formattable

  def display_welcome_message
    clear
    puts <<~WELCOME
    Hi #{player.name}. Welcome to Twenty-One!
    You are playing against #{dealer.name}.
    The first to win #{Game::WINS_LIMIT} games is the Champion!
    Press enter to continue.
    WELCOME
    blank_line
    gets
  end

  def display_header
    clear
    puts "You are playing Twenty One! " \
      "Remember, first to #{Game::WINS_LIMIT} games is the Champion!"
    display_scores
    single_line
  end

  def display_initial_hand
    puts "#{name} has #{hand[0]} and an unknown card."
  end

  def display_turn
    puts "#{name}'s turn..."
  end

  def display_hit
    puts "#{name} chose to hit."
  end

  def display_stay
    puts "#{name} stayed at #{total}."
    single_line
  end

  def display_hand
    puts "#{name} has #{joinor(hand.dup)}, for a total of #{total}."
  end

  def display_tie
    double_line
    puts "It's a tie!"
  end

  def display_winner(participant)
    double_line
    puts "#{participant.name} won!"
    display_scores
  end

  def display_scores
    puts "Score: #{player.name} = #{player.score}, " \
      "#{dealer.name} = #{dealer.score}."
  end

  def display_busted
    puts "Oh dear, #{name} has gone bust!"
    single_line
  end

  def display_champion
    puts "#{champion.name} won #{Game::WINS_LIMIT} games and is the CHAMPION!"
  end

  def play_again?
    ask_yes_no_question("Would you like to play another match? (y/n)")
  end

  def continue_match_message
    double_line
    puts "Rmember, first to #{Game::WINS_LIMIT} is the champion."
    answer = ask_closed_question(
      "Press enter to continue the match (or 'q' to quit this match).",
      ["", "q"]
    )
    clear
    answer.empty? ? true : false
  end

  def display_rematch_message
    clear
    puts <<~REMATCH
    Hi #{player.name}. Welcome back to Twenty-One!
    You are playing against #{dealer.name}.
    Remember, the first to win #{Game::WINS_LIMIT} games is the Champion!
    REMATCH
    blank_line
  end

  def display_goodbye_message
    puts "Thank you for playing Twenty-One! Goodbye!"
    blank_line
  end
end

module Hand
  CARD_RANKS_AND_VALUES = {
    '2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6, '7' => 7, '8' => 8,
    '9' => 9, '10' => 10, 'Jack' => 10, 'Queen' => 10, 'King' => 10, 'Ace' => 1
  }
  BUST_VALUE = 21
  ACE_VALUE_ALTERNATE = 10
  ACE_VALUE_LIMIT = 11

  def total
    value = total_with_aces_as_one
    total_with_aces_as_alternate(value)
  end

  def total_with_aces_as_one
    hand.reduce(0) do |sum, card|
      sum += CARD_RANKS_AND_VALUES.fetch(card.rank)
    end
  end

  def total_with_aces_as_alternate(value)
    aces = hand.count { |card| card.rank == 'Ace' }
    1.upto(aces) do
      value += ACE_VALUE_ALTERNATE if value <= ACE_VALUE_LIMIT
    end
    value
  end

  def busted?
    total > BUST_VALUE
  end
end

class Participant
  include Displayable
  include Questionable
  include Hand

  DEALER_NAME = "Alice"
  DEALER_STAY_VALUE = 17

  attr_reader :name, :deck
  attr_accessor :hand, :score, :bust

  def initialize(deck)
    @name = set_name
    @hand = []
    @score = 0
    @deck = deck
    @bust = false
  end

  def show_initial_hand
    display_initial_hand
  end

  def show_hand
    display_hand
  end

  def increment_score
    self.score += 1
  end

  def reset_hand
    self.hand = []
    self.bust = false
  end

  def reset_score
    self.score = 0
  end

  private

  def hit
    hand << deck.deal_card
    display_hit
    show_hand
    self.bust = true if busted?
  end

  def stay
    display_stay
  end
end

class Player < Participant
  def set_name
    ask_open_question("What's your name?", DEALER_NAME)
  end

  def turn
    loop do
      choice = ask_closed_question(
        "Would you like to (h)it or (s)tay?", ['h', 'hit', 's', 'stay']
      )
      return stay if choice[0] == 's'
      hit
      break if bust
    end
    display_busted
  end
end

class Dealer < Participant
  def set_name
    DEALER_NAME
  end

  def turn
    display_turn
    show_hand
    while total < DEALER_STAY_VALUE
      hit
    end
    bust ? display_busted : stay
  end
end

class Deck
  HEART = "\u2665"
  CLUB = "\u2663"
  DIAMOND = "\u2666"
  SPADE = "\u2660"

  CARD_SUITS = [HEART, CLUB, DIAMOND, SPADE]
  CARD_RANKS = ('2'..'10').to_a + ['Jack', 'Queen', 'King', 'Ace']

  attr_accessor :cards

  def initialize
    reset
  end

  def initial_deal(player, dealer)
    2.times do
      player.hand << deal_card
      dealer.hand << deal_card
    end
  end

  def deal_card
    cards.pop
  end

  def reset
    self.cards = CARD_SUITS.each_with_object([]) do |suit, arr|
      CARD_RANKS.each do |rank|
        arr << Card.new(rank, suit)
      end
    end
    cards.shuffle!
  end
end

class Card
  attr_reader :rank, :suit

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def to_s
    "#{rank}#{suit}"
  end
end

class Game
  include Displayable
  include Questionable
  include Hand

  WINS_LIMIT = 5

  attr_reader :player, :dealer
  attr_accessor :deck, :winner, :champion

  def initialize
    clear
    @deck = Deck.new
    @player = Player.new(deck)
    @dealer = Dealer.new(deck)
    @winner = nil
    @champion = nil
  end

  def start
    display_welcome_message
    loop do
      main_game
      end_match if champion
      break unless play_again?
      reset_match
      display_rematch_message
    end
    display_goodbye_message
  end

  private

  def main_game
    loop do
      display_header
      deal_cards
      show_initial_hands
      take_turns
      determine_result
      break if match_champion
      reset_game
      break unless continue_match_message
    end
  end

  def deal_cards
    deck.initial_deal(player, dealer)
  end

  def show_initial_hands
    dealer.show_initial_hand
    player.show_hand
  end

  def take_turns
    player.turn
    dealer.turn if !player.busted?
  end

  def determine_result
    self.winner = determine_winner
    update_score if winner
    declare_winner
  end

  def determine_winner
    if player.bust then dealer
    elsif dealer.bust then player
    elsif player.total > dealer.total then player
    elsif dealer.total > player.total then dealer
    end
  end

  def declare_winner
    dealer.show_hand
    player.show_hand
    case winner
    when nil then display_tie
    else display_winner(winner)
    end
  end

  def update_score
    winner.increment_score
  end

  def match_champion
    self.champion = if player.score == WINS_LIMIT
                      player
                    elsif dealer.score == WINS_LIMIT
                      dealer
                    end
  end

  def end_match
    dealer.show_hand
    player.show_hand
    display_champion
  end

  def reset_game
    deck.reset
    player.reset_hand
    dealer.reset_hand
    self.winner = nil
  end

  def reset_match
    reset_game
    player.reset_score
    dealer.reset_score
    self.champion = nil
  end
end

Game.new.start
