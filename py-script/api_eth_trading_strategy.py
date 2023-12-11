from flask import Flask, request, jsonify
import pandas as pd
from ta.trend import EMAIndicator
from ta.volatility import BollingerBands
from ta.momentum import StochasticOscillator

app = Flask(__name__)

def read_data_from_csv(file_path):
    df = pd.read_csv(file_path, parse_dates=['Date'])
    df = df.sort_values(by='Date')
    return df

def calculate_indicators(df):
    # EMAs
    df['ema20'] = EMAIndicator(close=df['Close'], window=20).ema_indicator()
    df['ema50'] = EMAIndicator(close=df['Close'], window=50).ema_indicator()

    # Bollinger Bands
    bb = BollingerBands(close=df['Close'], window=20, window_dev=2)
    df['bb_upper'] = bb.bollinger_hband()
    df['bb_lower'] = bb.bollinger_lband()

    # Stochastic Oscillator
    stoch = StochasticOscillator(high=df['High'], low=df['Low'], close=df['Close'], window=14, smooth_window=3)
    df['stoch_k'] = stoch.stoch()
    df['stoch_d'] = stoch.stoch_signal()

    return df

# SWING trading strategy
def should_enter_long(df):
    latest = df.iloc[-1]

    print("should_enter_long")
    print("latest['Date'] : ", latest['Date'])
    print("latest['Close']: ", latest['Close'])
    print("latest['ema20']: ", latest['ema20'])
    print("latest['ema50']: ", latest['ema50'])
    print("latest['bb_upper']: ", latest['bb_upper'])
    print("latest['stoch_k'] : ", latest['stoch_k'])
    print("latest['stoch_d'] : ", latest['stoch_d'])
    print("\n")

    #latest['stoch_k'] < 20 and
    return latest['Close'] > latest['ema20'] and \
           latest['Close'] > latest['ema50'] and \
           latest['Close'] > latest['bb_upper'] and \
           latest['stoch_k'] < 30 and \
           latest['stoch_k'] > latest['stoch_d']

def should_enter_short(df):
    latest = df.iloc[-1]

    print("should_enter_short")
    print("latest['Date'] : ", latest['Date'])
    print("latest['Close']: ", latest['Close'])
    print("latest['ema20']: ", latest['ema20'])
    print("latest['ema50']: ", latest['ema50'])
    print("latest['bb_lower']: ", latest['bb_lower'])
    print("latest['stoch_k'] : ", latest['stoch_k'])
    print("latest['stoch_d'] : ", latest['stoch_d'])
    print("\n")

    return latest['Close'] < latest['ema20'] and \
           latest['Close'] < latest['ema50'] and \
           latest['Close'] < latest['bb_lower'] and \
           latest['stoch_k'] > 70 and \
           latest['stoch_k'] < latest['stoch_d']

def should_exit_long(df, entry_price):
    latest = df.iloc[-1]
    profit_target = entry_price * 1.05
    stop_loss = entry_price * 0.98
    return latest['Close'] >= profit_target or latest['Close'] <= stop_loss

def should_exit_short(df, entry_price):
    latest = df.iloc[-1]
    profit_target = entry_price * 0.95
    stop_loss = entry_price * 1.02
    return latest['Close'] <= profit_target or latest['Close'] >= stop_loss

#RANGE trading strategy
def find_support(df, window=20):
    """Find support level based on the lowest price in the given window."""
    return df['Low'].rolling(window=window).min()

def find_resistance(df, window=20):
    """Find resistance level based on the highest price in the given window."""
    return df['High'].rolling(window=window).max()

def should_enter_range_long(df, support):
    """Enter long if the price is near the support level."""
    latest = df.iloc[-1]
    return latest['Close'] <= support * 1.02  # within 2% of the support

def should_enter_range_short(df, resistance):
    """Enter short if the price is near the resistance level."""
    latest = df.iloc[-1]
    return latest['Close'] >= resistance * 0.98  # within 2% of the resistance


@app.route('/trading_signal', methods=['POST'])
def trading_signal():
    data = request.json
    entry_price = float(data.get('entry_price')) if data.get('entry_price') else None
    file_path = 'data/ETH-USD.csv'

    df = read_data_from_csv(file_path)
    df = calculate_indicators(df)

    signal = None
    support = find_support(df)
    print("support   : ", support)
    resistance = find_resistance(df)
    print("resistance: ", resistance)

    if entry_price is None:
        # Check Swing Trading Strategy
        if should_enter_long(df):
            signal = "swing_long_entry"
        elif should_enter_short(df):
            signal = "swing_short_entry"

        # Check Range Trading Strategy
        elif should_enter_range_long(df, support.iloc[-1]):
            signal = "range_long_entry"
        elif should_enter_range_short(df, resistance.iloc[-1]):
            signal = "range_short_entry"
        else:
            signal = "no_signal"
    else:
        if should_exit_long(df, entry_price):
            signal = "long_exit"
        elif should_exit_short(df, entry_price):
            signal = "short_exit"
        else:
            signal = "no_signal"

    return jsonify({"signal": signal})

if __name__ == '__main__':
    app.run(debug=True)