import os
from markupsafe import escape
from flask import Flask, render_template
from flask_restful import Api, Resource
import resume_info


app = Flask(__name__)
api = Api(app)


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
            return d.get(key, {'error': 'non-existant key', 'keys': keys})        


api.add_resource(ResumeApiAll, '/api/all')
api.add_resource(ResumeApi, '/api/<int:id>')
api.add_resource(ResumeApiDetails, '/api/<int:id>/<string:key>')


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)