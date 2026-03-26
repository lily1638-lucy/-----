from flask import Blueprint, render_template, session

teacher_bp = Blueprint('teacher', __name__, url_prefix='/teacher')

def get_db():
    import psycopg2
    return psycopg2.connect(
        host='127.0.0.1',
        port=8888,
        user='postgres',
        password='postgres',
        database='teaching_system'
    )

@teacher_bp.route('/')
def index():
    if session.get('role') != 'teacher':
        return redirect('/')
    return render_template('teacher.html', user=session)

# ==================== 组员2在这里添加以下功能 ====================
# 1. 查看个人信息
# 2. 查看所教课程
# 3. 查看选课学生
# 4. 录入成绩
# 5. 修改成绩
# ================================================================