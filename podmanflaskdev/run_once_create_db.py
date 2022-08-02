from resume import db
import resume_info
import requests
import os



def main():
    # create db
    db.create_all()

    # populate db
def post():
    for d in work_history:
        r = requests.post('http://127.0.0.1:5000/addworkhistory', json=d, headers={'content-type': 'application/json'})
        l.append(r)

# if __name__ == '__main__':
#     main()
