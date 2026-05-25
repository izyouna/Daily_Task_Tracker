def test_register_and_login(client):
    # 1. Register a user
    register_response = client.post(
        "/api/v1/auth/register",
        json={"email": "test@example.com", "password": "testpassword123"}
    )
    assert register_response.status_code == 201
    data = register_response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data

    # Registering the same email again should fail
    duplicate_response = client.post(
        "/api/v1/auth/register",
        json={"email": "test@example.com", "password": "newpassword"}
    )
    assert duplicate_response.status_code == 400

    # 2. Login
    login_response = client.post(
        "/api/v1/auth/login",
        data={"username": "test@example.com", "password": "testpassword123"}
    )
    assert login_response.status_code == 200
    token_data = login_response.json()
    assert "access_token" in token_data
    assert token_data["token_type"] == "bearer"

    # Login with wrong credentials should fail
    wrong_login = client.post(
        "/api/v1/auth/login",
        data={"username": "test@example.com", "password": "wrongpassword"}
    )
    assert wrong_login.status_code == 400


def test_auth_protected_routes(client):
    # Fetching profile without auth should fail
    unauth_response = client.get("/api/v1/auth/me")
    assert unauth_response.status_code == 401


def test_categories_crud(client):
    # Register and login to get JWT
    client.post("/api/v1/auth/register", json={"email": "user@example.com", "password": "password"})
    login_response = client.post("/api/v1/auth/login", data={"username": "user@example.com", "password": "password"})
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create category
    cat_response = client.post(
        "/api/v1/categories/",
        headers=headers,
        json={"name": "Work", "color_hex": "#3498DB"}
    )
    assert cat_response.status_code == 201
    cat_data = cat_response.json()
    assert cat_data["name"] == "Work"
    assert cat_data["color_hex"] == "#3498DB"
    cat_id = cat_data["id"]

    # Duplicate name should fail
    dup_cat = client.post(
        "/api/v1/categories/",
        headers=headers,
        json={"name": "Work", "color_hex": "#FF0000"}
    )
    assert dup_cat.status_code == 400

    # 2. List categories
    list_response = client.get("/api/v1/categories/", headers=headers)
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1
    assert list_response.json()[0]["id"] == cat_id

    # 3. Delete category
    delete_response = client.delete(f"/api/v1/categories/{cat_id}", headers=headers)
    assert delete_response.status_code == 204

    # List categories should be empty now
    empty_list = client.get("/api/v1/categories/", headers=headers)
    assert len(empty_list.json()) == 0


def test_tags_crud(client):
    client.post("/api/v1/auth/register", json={"email": "tag_user@example.com", "password": "password"})
    login_response = client.post("/api/v1/auth/login", data={"username": "tag_user@example.com", "password": "password"})
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create tag
    tag_response = client.post("/api/v1/tags/", headers=headers, json={"name": "Urgent"})
    assert tag_response.status_code == 201
    tag_data = tag_response.json()
    assert tag_data["name"] == "Urgent"
    tag_id = tag_data["id"]

    # 2. List tags
    list_response = client.get("/api/v1/tags/", headers=headers)
    assert len(list_response.json()) == 1

    # 3. Delete tag
    del_response = client.delete(f"/api/v1/tags/{tag_id}", headers=headers)
    assert del_response.status_code == 204


def test_tasks_crud(client):
    client.post("/api/v1/auth/register", json={"email": "task_user@example.com", "password": "password"})
    login_response = client.post("/api/v1/auth/login", data={"username": "task_user@example.com", "password": "password"})
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Setup Category and Tag first
    cat_res = client.post("/api/v1/categories/", headers=headers, json={"name": "Personal", "color_hex": "#2ECC71"})
    cat_id = cat_res.json()["id"]

    tag_res = client.post("/api/v1/tags/", headers=headers, json={"name": "Important"})
    tag_id = tag_res.json()["id"]

    # 1. Create task
    task_response = client.post(
        "/api/v1/tasks/",
        headers=headers,
        json={
            "title": "Complete coding assignment",
            "description": "Using FastAPI and Flutter",
            "category_id": cat_id,
            "status": "Pending",
            "tag_ids": [tag_id]
        }
    )
    assert task_response.status_code == 201
    task_data = task_response.json()
    assert task_data["title"] == "Complete coding assignment"
    assert task_data["category_id"] == cat_id
    assert len(task_data["tags"]) == 1
    assert task_data["tags"][0]["id"] == tag_id
    task_id = task_data["id"]

    # 2. Get task by ID
    get_res = client.get(f"/api/v1/tasks/{task_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["title"] == "Complete coding assignment"

    # 3. Update task (Patch status to Completed)
    update_res = client.patch(
        f"/api/v1/tasks/{task_id}",
        headers=headers,
        json={"status": "Completed"}
    )
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "Completed"

    # 4. Search and List Tasks
    list_res = client.get("/api/v1/tasks/?search=coding", headers=headers)
    assert len(list_res.json()) == 1

    list_res_not_found = client.get("/api/v1/tasks/?search=invalid_query", headers=headers)
    assert len(list_res_not_found.json()) == 0

    # 5. Delete task
    del_res = client.delete(f"/api/v1/tasks/{task_id}", headers=headers)
    assert del_res.status_code == 204
