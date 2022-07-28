from flask import Flask, render_template
import os


app = Flask(__name__)



@app.route('/', methods=['GET'])
def home():
    return render_template('online_resume.html')


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)
