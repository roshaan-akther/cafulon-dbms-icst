import pymysql
import pymysql.cursors
from flask import Flask, render_template, request, redirect, url_for, flash

app = Flask(__name__)
app.secret_key = 'restaurant-demo-secret-2025'

DB = {
    'host': 'localhost',
    'user': 'root',
    'password': 'R00t@12345',
    'database': 'RestaurantDB',
    'cursorclass': pymysql.cursors.DictCursor
}


def db():
    return pymysql.connect(**DB)


def execute(sql, params=None, fetch=True, commit=False):
    conn = db()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            if commit:
                conn.commit()
                return cur.lastrowid
            if fetch:
                return cur.fetchall()
            return None
    finally:
        conn.close()


# ─── Dashboard ────────────────────────────────────────────────
@app.route('/')
def dashboard():
    stats = {
        'customers': execute("SELECT COUNT(*) AS c FROM Customers")[0]['c'],
        'employees': execute("SELECT COUNT(*) AS c FROM Employees")[0]['c'],
        'menu': execute("SELECT COUNT(*) AS c FROM MenuItems")[0]['c'],
        'orders': execute("SELECT COUNT(*) AS c FROM Orders")[0]['c'],
        'reservations': execute("SELECT COUNT(*) AS c FROM Reservations")[0]['c'],
        'revenue': execute("SELECT COALESCE(SUM(TotalAmount),0) AS c FROM Orders WHERE Status='Completed'")[0]['c'],
        'pending_orders': execute("SELECT COUNT(*) AS c FROM Orders WHERE Status IN ('Pending','Preparing')")[0]['c'],
        'today_reservations': execute("SELECT COUNT(*) AS c FROM Reservations WHERE ReservationDate=CURRENT_DATE")[0]['c'],
    }
    recent_orders = execute("""
        SELECT o.OrderID, CONCAT(c.FirstName,' ',c.LastName) AS Customer,
               o.TotalAmount, o.Status, o.OrderDate
        FROM Orders o LEFT JOIN Customers c ON o.CustomerID=c.CustomerID
        ORDER BY o.OrderDate DESC LIMIT 5
    """)
    return render_template('dashboard.html', stats=stats, recent_orders=recent_orders)


# ═══════════════════════════════════════════════════════════════
#  CUSTOMERS
# ═══════════════════════════════════════════════════════════════
@app.route('/customers')
def customer_list():
    rows = execute("SELECT * FROM Customers ORDER BY CustomerID DESC")
    return render_template('customers.html', customers=rows)


@app.route('/customers/add', methods=['GET', 'POST'])
def customer_add():
    if request.method == 'POST':
        f = request.form
        try:
            execute("""INSERT INTO Customers (FirstName,LastName,Phone,Email,Address,City)
                       VALUES (%s,%s,%s,%s,%s,%s)""",
                    (f['FirstName'], f['LastName'], f['Phone'], f['Email'],
                     f['Address'], f['City']), commit=True)
            flash('Customer added successfully', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('customer_list'))
    return render_template('customer_form.html', customer=None, title='Add Customer')


@app.route('/customers/<int:id>/edit', methods=['GET', 'POST'])
def customer_edit(id):
    if request.method == 'POST':
        f = request.form
        try:
            execute("""UPDATE Customers SET FirstName=%s,LastName=%s,Phone=%s,
                       Email=%s,Address=%s,City=%s WHERE CustomerID=%s""",
                    (f['FirstName'], f['LastName'], f['Phone'], f['Email'],
                     f['Address'], f['City'], id), commit=True)
            flash('Customer updated', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('customer_list'))
    row = execute("SELECT * FROM Customers WHERE CustomerID=%s", (id,))
    if not row:
        flash('Customer not found', 'danger')
        return redirect(url_for('customer_list'))
    return render_template('customer_form.html', customer=row[0], title='Edit Customer')


@app.route('/customers/<int:id>/delete', methods=['POST'])
def customer_delete(id):
    try:
        execute("DELETE FROM Customers WHERE CustomerID=%s", (id,), commit=True)
        flash('Customer deleted', 'success')
    except Exception as e:
        flash(f'Cannot delete: {e}', 'danger')
    return redirect(url_for('customer_list'))


# ═══════════════════════════════════════════════════════════════
#  EMPLOYEES
# ═══════════════════════════════════════════════════════════════
@app.route('/employees')
def employee_list():
    rows = execute("SELECT * FROM Employees ORDER BY EmployeeID DESC")
    return render_template('employees.html', employees=rows)


@app.route('/employees/add', methods=['GET', 'POST'])
def employee_add():
    if request.method == 'POST':
        f = request.form
        try:
            execute("""INSERT INTO Employees (FirstName,LastName,Position,Phone,Email,Salary,HireDate,Shift)
                       VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""",
                    (f['FirstName'], f['LastName'], f['Position'], f['Phone'],
                     f['Email'], f['Salary'], f['HireDate'], f['Shift']), commit=True)
            flash('Employee added', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('employee_list'))
    return render_template('employee_form.html', emp=None, title='Add Employee')


@app.route('/employees/<int:id>/edit', methods=['GET', 'POST'])
def employee_edit(id):
    if request.method == 'POST':
        f = request.form
        try:
            execute("""UPDATE Employees SET FirstName=%s,LastName=%s,Position=%s,
                       Phone=%s,Email=%s,Salary=%s,HireDate=%s,Shift=%s WHERE EmployeeID=%s""",
                    (f['FirstName'], f['LastName'], f['Position'], f['Phone'],
                     f['Email'], f['Salary'], f['HireDate'], f['Shift'], id), commit=True)
            flash('Employee updated', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('employee_list'))
    row = execute("SELECT * FROM Employees WHERE EmployeeID=%s", (id,))
    if not row:
        flash('Employee not found', 'danger')
        return redirect(url_for('employee_list'))
    return render_template('employee_form.html', emp=row[0], title='Edit Employee')


@app.route('/employees/<int:id>/delete', methods=['POST'])
def employee_delete(id):
    try:
        execute("DELETE FROM Employees WHERE EmployeeID=%s", (id,), commit=True)
        flash('Employee deleted', 'success')
    except Exception as e:
        flash(f'Cannot delete: {e}', 'danger')
    return redirect(url_for('employee_list'))


# ═══════════════════════════════════════════════════════════════
#  MENU ITEMS
# ═══════════════════════════════════════════════════════════════
@app.route('/menu')
def menu_list():
    rows = execute("""
        SELECT mi.*, mc.CategoryName
        FROM MenuItems mi JOIN MenuCategories mc ON mi.CategoryID=mc.CategoryID
        ORDER BY mc.CategoryName, mi.ItemName
    """)
    return render_template('menu.html', items=rows)


@app.route('/menu/add', methods=['GET', 'POST'])
def menu_add():
    cats = execute("SELECT * FROM MenuCategories ORDER BY CategoryName")
    if request.method == 'POST':
        f = request.form
        try:
            execute("""INSERT INTO MenuItems (CategoryID,ItemName,Description,Price,PreparationTime)
                       VALUES (%s,%s,%s,%s,%s)""",
                    (f['CategoryID'], f['ItemName'], f['Description'],
                     f['Price'], f['PreparationTime'] or None), commit=True)
            flash('Menu item added', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('menu_list'))
    return render_template('menu_form.html', item=None, categories=cats, title='Add Menu Item')


@app.route('/menu/<int:id>/edit', methods=['GET', 'POST'])
def menu_edit(id):
    cats = execute("SELECT * FROM MenuCategories ORDER BY CategoryName")
    if request.method == 'POST':
        f = request.form
        try:
            execute("""UPDATE MenuItems SET CategoryID=%s,ItemName=%s,Description=%s,
                       Price=%s,PreparationTime=%s WHERE ItemID=%s""",
                    (f['CategoryID'], f['ItemName'], f['Description'],
                     f['Price'], f['PreparationTime'] or None, id), commit=True)
            flash('Menu item updated', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('menu_list'))
    row = execute("SELECT * FROM MenuItems WHERE ItemID=%s", (id,))
    if not row:
        flash('Item not found', 'danger')
        return redirect(url_for('menu_list'))
    return render_template('menu_form.html', item=row[0], categories=cats, title='Edit Menu Item')


@app.route('/menu/<int:id>/delete', methods=['POST'])
def menu_delete(id):
    try:
        execute("DELETE FROM MenuItems WHERE ItemID=%s", (id,), commit=True)
        flash('Menu item deleted', 'success')
    except Exception as e:
        flash(f'Cannot delete: {e}', 'danger')
    return redirect(url_for('menu_list'))


# ═══════════════════════════════════════════════════════════════
#  RESERVATIONS
# ═══════════════════════════════════════════════════════════════
@app.route('/reservations')
def reservation_list():
    rows = execute("""
        SELECT r.*, CONCAT(c.FirstName,' ',c.LastName) AS CustomerName,
               t.TableNumber, CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName
        FROM Reservations r
        JOIN Customers c ON r.CustomerID=c.CustomerID
        JOIN RestaurantTables t ON r.TableID=t.TableID
        LEFT JOIN Employees e ON r.EmployeeID=e.EmployeeID
        ORDER BY r.ReservationDate DESC, r.ReservationTime DESC
    """)
    return render_template('reservations.html', reservations=rows)


@app.route('/reservations/add', methods=['GET', 'POST'])
def reservation_add():
    customers = execute("SELECT CustomerID, FirstName, LastName FROM Customers ORDER BY FirstName")
    tables = execute("SELECT TableID, TableNumber, Capacity FROM RestaurantTables WHERE IsActive=TRUE ORDER BY TableNumber")
    employees = execute("SELECT EmployeeID, FirstName, LastName FROM Employees WHERE Position IN ('Manager','Hostess','Waiter') ORDER BY FirstName")
    if request.method == 'POST':
        f = request.form
        try:
            execute("""INSERT INTO Reservations (CustomerID,TableID,EmployeeID,ReservationDate,
                       ReservationTime,PartySize,Status,SpecialRequests)
                       VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""",
                    (f['CustomerID'], f['TableID'], f.get('EmployeeID') or None,
                     f['ReservationDate'], f['ReservationTime'], f['PartySize'],
                     f['Status'], f.get('SpecialRequests', '')), commit=True)
            flash('Reservation created', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('reservation_list'))
    return render_template('reservation_form.html', res=None, customers=customers,
                           tables=tables, employees=employees, title='Add Reservation')


@app.route('/reservations/<int:id>/edit', methods=['GET', 'POST'])
def reservation_edit(id):
    customers = execute("SELECT CustomerID, FirstName, LastName FROM Customers ORDER BY FirstName")
    tables = execute("SELECT TableID, TableNumber, Capacity FROM RestaurantTables WHERE IsActive=TRUE ORDER BY TableNumber")
    employees = execute("SELECT EmployeeID, FirstName, LastName FROM Employees WHERE Position IN ('Manager','Hostess','Waiter') ORDER BY FirstName")
    if request.method == 'POST':
        f = request.form
        try:
            execute("""UPDATE Reservations SET CustomerID=%s,TableID=%s,EmployeeID=%s,
                       ReservationDate=%s,ReservationTime=%s,PartySize=%s,Status=%s,SpecialRequests=%s
                       WHERE ReservationID=%s""",
                    (f['CustomerID'], f['TableID'], f.get('EmployeeID') or None,
                     f['ReservationDate'], f['ReservationTime'], f['PartySize'],
                     f['Status'], f.get('SpecialRequests', ''), id), commit=True)
            flash('Reservation updated', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('reservation_list'))
    row = execute("SELECT * FROM Reservations WHERE ReservationID=%s", (id,))
    if not row:
        flash('Reservation not found', 'danger')
        return redirect(url_for('reservation_list'))
    return render_template('reservation_form.html', res=row[0], customers=customers,
                           tables=tables, employees=employees, title='Edit Reservation')


@app.route('/reservations/<int:id>/delete', methods=['POST'])
def reservation_delete(id):
    try:
        execute("DELETE FROM Reservations WHERE ReservationID=%s", (id,), commit=True)
        flash('Reservation deleted', 'success')
    except Exception as e:
        flash(f'Cannot delete: {e}', 'danger')
    return redirect(url_for('reservation_list'))


# ═══════════════════════════════════════════════════════════════
#  ORDERS  (with OrderDetails)
# ═══════════════════════════════════════════════════════════════
@app.route('/orders')
def order_list():
    rows = execute("""
        SELECT o.*, CONCAT(c.FirstName,' ',c.LastName) AS CustomerName,
               CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName
        FROM Orders o
        LEFT JOIN Customers c ON o.CustomerID=c.CustomerID
        JOIN Employees e ON o.EmployeeID=e.EmployeeID
        ORDER BY o.OrderDate DESC
    """)
    return render_template('orders.html', orders=rows)


@app.route('/orders/add', methods=['GET', 'POST'])
def order_add():
    customers = execute("SELECT CustomerID, FirstName, LastName FROM Customers ORDER BY FirstName")
    employees = execute("SELECT EmployeeID, FirstName, LastName FROM Employees ORDER BY FirstName")
    tables = execute("SELECT TableID, TableNumber FROM RestaurantTables WHERE IsActive=TRUE ORDER BY TableNumber")
    menu_items = execute("SELECT mi.ItemID, mi.ItemName, mi.Price, mc.CategoryName FROM MenuItems mi "
                         "JOIN MenuCategories mc ON mi.CategoryID=mc.CategoryID "
                         "WHERE mi.IsAvailable=TRUE ORDER BY mc.CategoryName, mi.ItemName")
    if request.method == 'POST':
        f = request.form
        customer_id = f.get('CustomerID') or None
        table_id = f.get('TableID') or None
        items = request.form.getlist('item_id[]')
        qty = request.form.getlist('qty[]')
        if not items or all(not i for i in items):
            flash('Please add at least one item', 'danger')
            return render_template('order_form.html', customers=customers, employees=employees,
                                   tables=tables, menu_items=menu_items, order=None, title='New Order')
        conn = db()
        try:
            with conn.cursor() as cur:
                cur.execute("""INSERT INTO Orders (CustomerID,EmployeeID,TableID,OrderType,Status)
                               VALUES (%s,%s,%s,%s,%s)""",
                            (customer_id, f['EmployeeID'], table_id, f['OrderType'], 'Pending'))
                order_id = cur.lastrowid
                total = 0
                for i in range(len(items)):
                    if not items[i] or not qty[i] or int(qty[i]) <= 0:
                        continue
                    cur.execute("SELECT Price FROM MenuItems WHERE ItemID=%s", (items[i],))
                    price = cur.fetchone()['Price']
                    subtotal = price * int(qty[i])
                    cur.execute("""INSERT INTO OrderDetails (OrderID,ItemID,Quantity,UnitPrice)
                                   VALUES (%s,%s,%s,%s)""",
                                (order_id, items[i], qty[i], price))
                    total += subtotal
                cur.execute("UPDATE Orders SET TotalAmount=%s WHERE OrderID=%s", (total, order_id))
                conn.commit()
            flash(f'Order #{order_id} created successfully', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'Error: {e}', 'danger')
        finally:
            conn.close()
        return redirect(url_for('order_list'))
    return render_template('order_form.html', customers=customers, employees=employees,
                           tables=tables, menu_items=menu_items, order=None, title='New Order')


@app.route('/orders/<int:id>')
def order_detail(id):
    order = execute("""
        SELECT o.*, CONCAT(c.FirstName,' ',c.LastName) AS CustomerName,
               CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName,
               t.TableNumber
        FROM Orders o
        LEFT JOIN Customers c ON o.CustomerID=c.CustomerID
        JOIN Employees e ON o.EmployeeID=e.EmployeeID
        LEFT JOIN RestaurantTables t ON o.TableID=t.TableID
        WHERE o.OrderID=%s
    """, (id,))
    if not order:
        flash('Order not found', 'danger')
        return redirect(url_for('order_list'))
    items = execute("""
        SELECT od.*, mi.ItemName, mc.CategoryName
        FROM OrderDetails od
        JOIN MenuItems mi ON od.ItemID=mi.ItemID
        JOIN MenuCategories mc ON mi.CategoryID=mc.CategoryID
        WHERE od.OrderID=%s
    """, (id,))
    payments = execute("SELECT * FROM Payments WHERE OrderID=%s", (id,))
    return render_template('order_detail.html', order=order[0], items=items, payments=payments)


@app.route('/orders/<int:id>/status', methods=['POST'])
def order_status(id):
    status = request.form.get('status')
    valid = ['Pending', 'Preparing', 'Served', 'Completed', 'Cancelled']
    if status in valid:
        execute("UPDATE Orders SET Status=%s WHERE OrderID=%s", (status, id), commit=True)
        flash(f'Order #{id} status updated to {status}', 'success')
    else:
        flash('Invalid status', 'danger')
    return redirect(url_for('order_detail', id=id))


@app.route('/orders/<int:id>/delete', methods=['POST'])
def order_delete(id):
    try:
        execute("DELETE FROM Orders WHERE OrderID=%s", (id,), commit=True)
        flash('Order deleted', 'success')
    except Exception as e:
        flash(f'Cannot delete: {e}', 'danger')
    return redirect(url_for('order_list'))


# ═══════════════════════════════════════════════════════════════
#  PAYMENTS
# ═══════════════════════════════════════════════════════════════
@app.route('/payments')
def payment_list():
    rows = execute("""
        SELECT p.*, o.TotalAmount AS OrderTotal,
               CONCAT(c.FirstName,' ',c.LastName) AS CustomerName
        FROM Payments p
        JOIN Orders o ON p.OrderID=o.OrderID
        LEFT JOIN Customers c ON o.CustomerID=c.CustomerID
        ORDER BY p.PaymentDate DESC
    """)
    return render_template('payments.html', payments=rows)


@app.route('/payments/add', methods=['GET', 'POST'])
def payment_add():
    unpaid = execute("""
        SELECT o.OrderID, o.TotalAmount, CONCAT(c.FirstName,' ',c.LastName) AS Customer
        FROM Orders o LEFT JOIN Customers c ON o.CustomerID=c.CustomerID
        WHERE o.Status='Completed' AND o.OrderID NOT IN (SELECT OrderID FROM Payments)
        ORDER BY o.OrderID
    """)
    if request.method == 'POST':
        f = request.form
        try:
            execute("""INSERT INTO Payments (OrderID,Amount,PaymentMethod,TransactionReference,IsPaid)
                       VALUES (%s,%s,%s,%s,%s)""",
                    (f['OrderID'], f['Amount'], f['PaymentMethod'],
                     f.get('TransactionReference', ''), 1), commit=True)
            flash('Payment recorded', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
        return redirect(url_for('payment_list'))
    return render_template('payment_form.html', unpaid_orders=unpaid, title='Record Payment')


@app.route('/payments/<int:id>/delete', methods=['POST'])
def payment_delete(id):
    try:
        execute("DELETE FROM Payments WHERE PaymentID=%s", (id,), commit=True)
        flash('Payment deleted', 'success')
    except Exception as e:
        flash(f'Cannot delete: {e}', 'danger')
    return redirect(url_for('payment_list'))


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
