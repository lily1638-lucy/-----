from flask import Blueprint, render_template, request, redirect, session
import hashlib
import psycopg2
import psycopg2.extras

auth_bp = Blueprint('auth', __name__)

# 数据库连接配置 - 每个人改成自己的
def get_db():
    return psycopg2.connect(
        host='127.0.0.1',
        port=8888,
        user='postgres',
        password='postgres',
        database='teaching_system'
    )

def md5_hash(text):
    return hashlib.md5(text.encode()).hexdigest()

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        return render_template('login.html')
    
    username = request.form.get('username')
    password = md5_hash(request.form.get('password'))
    
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute(
        "SELECT id, username, real_name, role FROM users WHERE username=%s AND password=%s",
        (username, password)
    )
    user = cur.fetchone()
    cur.close()
    conn.close()
    
    if user:
        session['user_id'] = user['id']
        session['username'] = user['username']
        session['real_name'] = user['real_name']
        session['role'] = user['role']
        
        if user['role'] == 'student':
            return redirect('/student/')
        elif user['role'] == 'teacher':
            return redirect('/teacher/')
        else:
            return redirect('/admin/')
    else:
        return render_template('login.html', error='用户名或密码错误')

@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'GET':
        return render_template('register.html')
    
    username = request.form.get('username')
    password = md5_hash(request.form.get('password'))
    real_name = request.form.get('real_name')
    role = request.form.get('role')
    
    conn = get_db()
    cur = conn.cursor()
    
    # 检查用户名是否存在
    cur.execute("SELECT id FROM users WHERE username=%s", (username,))
    if cur.fetchone():
        cur.close()
        conn.close()
        return render_template('register.html', error='用户名已存在')
    
    # 插入用户
    cur.execute(
        "INSERT INTO users (username, password, real_name, role) VALUES (%s, %s, %s, %s) RETURNING id",
        (username, password, real_name, role)
    )
    user_id = cur.fetchone()[0]
    
    # 如果是学生，插入学生表
    if role == 'student':
        student_id = f"S{user_id:04d}"
        cur.execute(
            "INSERT INTO students (user_id, student_id) VALUES (%s, %s)",
            (user_id, student_id)
        )
    # 如果是教师，插入教师表
    elif role == 'teacher':
        teacher_id = f"T{user_id:04d}"
        cur.execute(
            "INSERT INTO teachers (user_id, teacher_id) VALUES (%s, %s)",
            (user_id, teacher_id)
        )
    
    conn.commit()
    cur.close()
    conn.close()
    
    return redirect('/auth/login')

@auth_bp.route('/logout')
def logout():
    session.clear()
    return redirect('/auth/login')