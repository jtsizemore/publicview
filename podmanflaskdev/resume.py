import os
from markupsafe import escape
from flask import Flask, render_template, request, jsonify
from flask_restful import Api, Resource
from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
import resume_info


# get absolute directory path
abs_file_path = os.path.abspath(os.path.dirname(__file__))

app = Flask(__name__)
api = Api(app)


# sqlalchemy db
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(abs_file_path, 'resumedb.sqlite')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
ma = Marshmallow(app)


class ResumeApiAll(Resource):
    def get(self):
        return {
            'data': f'Please enter a work history id between 1 and {len(resume_info.work_history)}: /api/<int:id>',
            'endpoints': resume_info.work_history
        }


class ResumeApi(Resource):
    def get(self, id):
        if id in resume_info.work_history.keys():
            return resume_info.work_history[id]
        else:
            return {'error': f'Please enter a work history id between 1 and {len(resume_info.work_history)}: /api/<int:id>'}


class ResumeApiDetails(Resource):
    def get(self, id, key):
        d = resume_info.work_history[id]
        keys = [ k for k in d.keys() ]
        if id in resume_info.work_history.keys():
            try:
                return d[key]
            except KeyError as e:
                return {'error': 'non-existant key', 'keys': keys}, 404


api.add_resource(ResumeApiAll, '/api/all')
api.add_resource(ResumeApi, '/api/<int:id>')
api.add_resource(ResumeApiDetails, '/api/<int:id>/<string:key>')


class ResumeWorkHistory(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    company = db.Column(db.String(115))
    date = db.Column(db.String(15))
    role = db.Column(db.String(115))
    description = db.Column(db.String(115))

    def __init__(self, company, date, role, description):
        self.company = company
        self.date = date
        self.role = role
        self.description = description


class WorkHistorySchema(ma.Schema):
    class Meta:
        fields = ('id', 'company', 'date', 'role', 'description')

work_history_singlular_schema = WorkHistorySchema()
work_history_plural_schema = WorkHistorySchema(many=True)


# flask routes
@app.context_processor
def resume_info_template():
    return dict(r=resume_info)


@app.route('/')
@app.route('/home', methods=['GET'])
def home():
    return render_template('home.html', title='Home')


@app.route('/workhistory', methods=['GET'])
def history():
    return render_template('workhistory.html', title='Work History')


@app.route('/clearance')
def clearance():
    return render_template('clearance.html', title='Clearance')


@app.route('/about')
def about():
    return render_template('about.html', title='About JTS')

@app.route('/api')
@app.route('/api/')
def api_info():
    return render_template('api_info.html', title='About JTS')


@app.route('/addworkhistory', methods=['POST'])
def add_workhistory():
    company = request.json['company']
    date = request.json['date']
    role = request.json['role']
    description = request.json['description']

    new_work_history = ResumeWorkHistory(company, date, role, description)
    db.session.add(new_work_history)
    db.session.commit()

    return work_history_singlular_schema.jsonify(new_work_history)


@app.route('/workhistoryall', methods=['GET'])
def get_all():
    all_work_history = ResumeWorkHistory.query.all()
    result = work_history_plural_schema.dump(all_work_history)
    return jsonify(result)


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)
