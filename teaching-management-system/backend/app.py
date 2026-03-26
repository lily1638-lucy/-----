from flask import Flask, render_template, redirect, session
import os

app = Flask(__name__, template_folder='../templates')
app.secret_key = 'your-secret-key-123456'

# 导入蓝图
from auth import auth_bp
from student import student_bp
from teacher import teacher_bp
from admin import admin_bp

# 注册蓝图
app.register_blueprint(auth_bp, url_prefix='/auth')
app.register_blueprint(student_bp, url_prefix='/student')
app.register_blueprint(teacher_bp, url_prefix='/teacher')
app.register_blueprint(admin_bp, url_prefix='/admin')

@app.route('/')
def index():
    if 'user_id' in session:
        role = session.get('role')
        if role == 'student':
            return redirect('/student/')
        elif role == 'teacher':
            return redirect('/teacher/')
        elif role == 'admin':
            return redirect('/admin/')
    return redirect('/auth/login')

if __name__ == '__main__':
    app.run(debug=True, port=5000)