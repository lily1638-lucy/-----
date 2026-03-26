from flask import Blueprint, render_template, session

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

def get_db():
    import psycopg2
    return psycopg2.connect(
        host='127.0.0.1',
        port=8888,
        user='postgres',
        password='postgres',
        database='teaching_system'
    )

@admin_bp.route('/')
def index():
    if session.get('role') != 'admin':
        return redirect('/')
    return render_template('admin.html', user=session)

# ==================== 组员3在这里添加以下功能 ====================
# 1. 课程管理（增删改查）
# 2. 学生管理（增删改查）
# 3. 教师管理（增删改查）
# 4. 数据统计
# ================================================================