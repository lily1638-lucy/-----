from flask import Blueprint, render_template, session, request, jsonify

student_bp = Blueprint('student', __name__, url_prefix='/student')

# 数据库连接函数 - 复制auth.py里的get_db
def get_db():
    import psycopg2
    return psycopg2.connect(
        host='127.0.0.1',
        port=8888,
        user='postgres',
        password='postgres',
        database='teaching_system'
    )

@student_bp.route('/')
def index():
    if session.get('role') != 'student':
        return redirect('/')
    return render_template('student.html', user=session)

# ==================== 组员1在这里添加以下功能 ====================
# 1. 查看个人信息
# 2. 查看课程列表
# 3. 选课
# 4. 退课
# 5. 查看已选课程和成绩
# ================================================================