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
    
    role = request.form.get('role')
    identifier = request.form.get('identifier')  # 学号、工号或管理员编号
    real_name = request.form.get('real_name')
    username = request.form.get('username')
    password = md5_hash(request.form.get('password'))
    
    conn = get_db()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    
    # 1. 检查用户名是否已被注册
    cur.execute("SELECT id FROM users WHERE username=%s", (username,))
    if cur.fetchone():
        cur.close()
        conn.close()
        return render_template('register.html', error='用户名已存在')
    
    # 2. 根据角色验证身份是否存在
    if role == 'student':
        # 验证学号是否存在
        cur.execute(
            "SELECT student_id, name FROM students WHERE student_id=%s AND status='active'",
            (identifier,)
        )
        person = cur.fetchone()
        if not person:
            cur.close()
            conn.close()
            return render_template('register.html', error='学号不存在或无效，请联系教务处')
        
        # 检查该学生是否已经注册过账号
        cur.execute("SELECT id FROM users WHERE student_id=%s", (identifier,))
        if cur.fetchone():
            cur.close()
            conn.close()
            return render_template('register.html', error='该学号已注册账号')
        
        # 验证姓名是否匹配
        if person['name'] != real_name:
            cur.close()
            conn.close()
            return render_template('register.html', error='姓名与学号不匹配')
        
        # 注册用户
        cur.execute(
            """INSERT INTO users (username, password, real_name, role, student_id, email) 
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id""",
            (username, password, real_name, 'student', identifier, f"{identifier}@school.edu")
        )
        
    elif role == 'teacher':
        # 验证工号是否存在
        cur.execute(
            "SELECT teacher_id, name FROM teachers WHERE teacher_id=%s AND status='active'",
            (identifier,)
        )
        person = cur.fetchone()
        if not person:
            cur.close()
            conn.close()
            return render_template('register.html', error='工号不存在或无效，请联系人事处')
        
        # 检查该教师是否已经注册过账号
        cur.execute("SELECT id FROM users WHERE teacher_id=%s", (identifier,))
        if cur.fetchone():
            cur.close()
            conn.close()
            return render_template('register.html', error='该工号已注册账号')
        
        # 验证姓名是否匹配
        if person['name'] != real_name:
            cur.close()
            conn.close()
            return render_template('register.html', error='姓名与工号不匹配')
        
        # 注册用户
        cur.execute(
            """INSERT INTO users (username, password, real_name, role, teacher_id, email) 
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id""",
            (username, password, real_name, 'teacher', identifier, f"{identifier}@school.edu")
        )
        
    elif role == 'admin':
        # 验证管理员编号是否存在
        cur.execute(
            "SELECT admin_id, name FROM admins WHERE admin_id=%s AND status='active'",
            (identifier,)
        )
        person = cur.fetchone()
        if not person:
            cur.close()
            conn.close()
            return render_template('register.html', error='管理员编号不存在或无效')
        
        # 检查该管理员是否已经注册过账号
        cur.execute("SELECT id FROM users WHERE admin_id=%s", (identifier,))
        if cur.fetchone():
            cur.close()
            conn.close()
            return render_template('register.html', error='该管理员编号已注册账号')
        
        # 验证姓名是否匹配
        if person['name'] != real_name:
            cur.close()
            conn.close()
            return render_template('register.html', error='姓名与管理员编号不匹配')
        
        # 注册用户
        cur.execute(
            """INSERT INTO users (username, password, real_name, role, admin_id, email) 
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id""",
            (username, password, real_name, 'admin', identifier, f"{identifier}@school.edu")
        )
    
    else:
        cur.close()
        conn.close()
        return render_template('register.html', error='无效的角色')
    
    user_id = cur.fetchone()['id']
    conn.commit()
    cur.close()
    conn.close()
    
    return redirect('/auth/login')

@auth_bp.route('/logout')
def logout():
    session.clear()
    return redirect('/auth/login')