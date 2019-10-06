//
//  OneGameView.swift
//  Hanabi Ai
//
//  Created by Geoff Hom on 9/18/19.
//  Copyright © 2019 Geoff Hom. All rights reserved.
//

import SwiftUI

// Interface for auto-playing one game.
struct OneGameView: View {
    @ObservedObject var game: Game
    
    init(numberOfPlayers: Int, deckSetup: DeckSetup, customDeckDescription: String) {
        let game = Game(numberOfPlayers: numberOfPlayers, deckSetup: deckSetup, customDeckDescription: customDeckDescription)
        self.game = game
    }
    
    var body: some View {
        Form {
            DeckSetupSection(deckSetup: game.deckSetup, startingDeck: game.startingDeck)
            StartingSetupSection(game: game)
            TurnsSection(turns: game.turns)
            ResultsSection()
        }
        .navigationBarTitle(Text("One Game"), displayMode: .inline)
    }
}

// MARK: DeckSetupSection

// Deck setup and deck used.
struct DeckSetupSection: View {
    let deckSetup: DeckSetup
    let startingDeck: Deck
    var body: some View {
        Section(header: Text("Deck Setup")) {
            // `Prefix` has non-breaking space.
            ColoredCardsText(cards: startingDeck.cards, prefix: "\(deckSetup.name): ")
                .font(.caption)
        }
    }
}

// MARK: StartingSetupSection

/// The game state after dealing hands, plus the "Play" button.
struct StartingSetupSection: View {
    let game: Game
    var body: some View {
        let firstTurn = game.turns.first!
        return Section(header: Text("Starting Setup")) {
            StartingHandsAndDeckGroup(hands: firstTurn.hands, deck: firstTurn.deck)
            PlayButton(game: game)
        }
    }
}

/// The starting hands, and the remaining deck.
struct StartingHandsAndDeckGroup: View {
    let hands: [Hand]
    let deck: Deck
    var body: some View {
        Group {
            HStack(spacing: 0) {
                Text("Hands: ")
                VStack(alignment: .leading) {
                    // TODO 2: If I get rid of this ForEach, I won't need Hand to be Identifiable.
                    // TODO 1: map should work? like, hands.map{CCT(cards: $0.cards)}
                    ForEach(hands) { hand in
                        ColoredCardsText(cards: hand.cards)
                    }
                }
            }
    
            // `Prefix` has non-breaking space.
            ColoredCardsText(cards: deck.cards, prefix: "Deck: ")
                .font(.caption)
        }
        .font(.caption)
    }
}

/// Card descriptions, in a row, colored by suit.
///
/// This returns `Text`, but it won't let me put that in the sig. So it doesn't allow `Text` modifiers externally. TODO: Make Text views functions instead? Or wait for Apple to fix? Probably make a function. Then I could do the prefix separately, which makes way more sense. And emphasis
///
/// - Parameters:
///   - cards: An `Array` of `Cards` ... TODO.
///   - prefix: A `String` ... TODO
///   - emphasis: A `Bool` ... TODO
/// - Returns: A `View`, but wish it were a `Text` ... TODO
struct ColoredCardsText: View {
    // TODO: how do I do this? I want it to be assigned only once. If user assigns it, great. If not, use default. So, use init
    let cards: [Card]
    let prefix: String
    
    // `Emphasis` is here, because don't know how to add `Text` modifiers to `ColoredCardsText`. (Won't compile.)
    let emphasis: Bool
    
    init(cards: [Card], prefix: String = "", emphasis: Bool = false) {
        self.cards = cards
        self.prefix = prefix
        self.emphasis = emphasis
    }
    
    var body: some View {
        
        // Each `Card` `description`, with color.
        let coloredCards = cards.map {
            Text("\($0.description)")
                .foregroundColor(colorForSuit($0.suit))
        }
        
        var text: Text = Text(prefix) + concatenate(coloredCards)
        if emphasis {
            text = text.bold()
        }
        return text
    }
}

/// The color to represent each suit.
func colorForSuit(_ suit: Suit) -> Color {
    var color: Color
    switch suit {
    case .green:
        color = .green
    case .red:
        color = .red
    case .white:
        color = .gray
    case .blue:
        color = .blue
    case .yellow:
        color = .yellow
    }
    return color
}

/// Starts playing the game that was set up.
struct PlayButton: View {
    let game: Game
    var body: some View {
        HStack {
            Spacer()
            Button(action: { self.game.play() }) {
                Text("Play")
            }
            Spacer()
        }
    }
}

// MARK: TurnsSection

/// Each turn in the game.
struct TurnsSection: View {
    let turns: [Turn]
    var body: some View {
        Section(header: TurnsSectionHeaderView()) {
            TurnHeaderView()
            // TODO: try as List? Then wouldn't need to reference `number`. map() should also work
            ForEach(turns, id: \.number) {
                TurnView(turn: $0)
            }

            //                    // Ugh. Lining stuff up can be done with GR and PreferenceKey, which is available but undocumented. Will wait for Apple to document better and move on to other stuff.
            // I want the rows to line up. E.g., Turn takes up 40% of row, grwby takes 40%, cs takes 20%
        }
    }
}

/// The text for the section header.
struct TurnsSectionHeaderView: View {
    // TODO: Add legend to UI via popover/context button, if that's doable on iPhone
    var body: some View {
        Text("Turns")
//        + Text(" (g/r/w/b/y: green/red/white/blue/yellow)")
//        + Text(" (C/S/D: Clues/Strikes/Deck)")
    }
}

/// Field descriptions for each turn.
struct TurnHeaderView: View {
    var body: some View {
        HStack {
            Text("Hands")
            ScoreHeaderView()
            Text("C/S/D")
            Text("Action")
        }
        .font(.caption)
    }
}

/// Return a `View` (i.e., `Text`) of the abbreviation of each suit, in order. Suits are separated for legibility and colored appropriately.
struct ScoreHeaderView: View {
    var body: some View {
        
        // Each abbreviation, with color.
        let suitTexts = Suit.allCases.sorted().map {
            Text("\($0.letter)").foregroundColor(colorForSuit($0))
        }

        return concatenate(suitTexts, withSeparator: "/")
    }
}

/// Return the `Text` formed by concatenating the given `texts`, optionally including a `separator` between each given `Text`.
///
/// - Parameters:
///   - texts: An `Array` of `Texts` to concatenate.
///   - separator: A `String` to include between each `Text` in the concatenation. The default is to have no separator.
/// - Returns: A `Text`, formed by concatenating the given `texts`. If a `separator` is given, it's included between each given `Text`.
func concatenate(_ texts: [Text], withSeparator separator: String? = nil) -> Text {
    let firstText = texts.first!
    let otherTexts = texts.dropFirst()
    guard let separator = separator else {
        return otherTexts.reduce(firstText, +)
    }
    return otherTexts.reduce(firstText, { x, y in
        x + Text(separator) + y
    })
}

/// Info needed to understand a turn.
struct TurnView: View {
    let turn: Turn
    var body: some View {
        HStack {
            TurnNumberView(number: turn.number)
            PlayerHandsView(hands: turn.hands, currentHandIndex: turn.currentHandIndex)
            ScorePilesView(scorePiles: turn.scorePiles)
            TokenPilesView(clues: turn.clues, strikes: turn.strikes, cardsInDeck: turn.deck.cards.count)
            ActionView(hands: turn.hands, currentHandIndex: turn.currentHandIndex, action: turn.action)
        }
        .font(.caption)
    }
}

/// Which turn it is.
struct TurnNumberView: View {
    let number: Int
    var body: some View {
        Text("\(number).")
    }
}

/// The players' cards. Current player is highlighted.
struct PlayerHandsView: View {
    let hands: [Hand]
    let currentHandIndex: Int
    var body: some View {
        VStack(alignment: .leading) {
            // TODO: try map()?
            ForEach((0 ..< hands.count)) { index in
                ColoredCardsText(cards: self.hands[index].cards, emphasis: index == self.currentHandIndex)
            }
        }
    }
}

/// Return a `View` (i.e., `Text`) of the scores in `scorePiles`. Scores are separated for legibility and colored appropriately.
///
/// Colorblind users may not know which score is for which suit. So, `ScorePilesView` should be used with `ScoreHeaderView`, which lists the suit order.
///
/// - Parameter scorePiles: (Someday, the docs will work with memberwise initializers…)
struct ScorePilesView: View {
    let scorePiles: [ScorePile]
    
    var body: some View {
        
        // Get each score; add color.
        let scoreTexts = scorePiles.map {
            Text("\($0.score)").foregroundColor(colorForSuit($0.suit))
        }
        
        return concatenate(scoreTexts, withSeparator: "/")
    }
}

/// Number of clues, strikes, cards in deck.
struct TokenPilesView: View {
    let clues: Int
    let strikes: Int
    let cardsInDeck: Int
    var body: some View {
        Text("\(clues)/\(strikes)/\(cardsInDeck)")
    }
}

/// Current player's action. Highlighted, to match highlighted hand.
struct ActionView: View {
    let hands: [Hand]
    let currentHandIndex: Int
    let action: Action?
    var body: some View {
        let actionString: String = action?.abbr ?? "??"
        return VStack {
            // try map()?
            ForEach((0 ..< hands.count)) { index in
                if index == self.currentHandIndex {
                    Text("\(actionString)").bold()
                } else {
                    Text("\n")
                }
            }
        }
    }
}

// MARK: ResultsSection

// The end of the game, or a summary.
struct ResultsSection: View {
    var body: some View {
        Section(header: Text("Results")) {
            Text("??")
                .font(.caption)
        }
    }
}

struct OneGameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // TODO: When I have other modes working, like 3+ players, will have to check if Live Preview works with that, or if code below needs to be modified.
            OneGameView(numberOfPlayers: 2, deckSetup: .random, customDeckDescription: "")
        }
    }
}

