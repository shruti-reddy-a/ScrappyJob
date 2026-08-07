from datetime import datetime
from unittest.mock import MagicMock
from services.db_service import should_run_job

def test_should_run_job_now():
    # When frequency is "Now", it should always return True regardless of db
    db_mock = MagicMock()
    current_time = datetime(2023, 1, 1, 12, 0)
    assert should_run_job(db_mock, "job123", "Now", current_time) is True

def test_should_run_job_no_previous_runs():
    db_mock = MagicMock()
    # Mocking a Firestore query returning empty
    query_mock = MagicMock()
    query_mock.where.return_value.order_by.return_value.limit.return_value.get.return_value = []
    db_mock.collection.return_value = query_mock
    
    current_time = datetime(2023, 1, 1, 12, 0)
    assert should_run_job(db_mock, "job123", "Every 4 Hours", current_time) is True

def test_should_run_job_every_4_hours():
    db_mock = MagicMock()
    query_mock = MagicMock()
    run_doc_mock = MagicMock()
    
    # Last run was 4 hours ago
    last_run_time = datetime(2023, 1, 1, 8, 0)
    run_doc_mock.to_dict.return_value = {"created_at": last_run_time}
    query_mock.where.return_value.order_by.return_value.limit.return_value.get.return_value = [run_doc_mock]
    db_mock.collection.return_value = query_mock
    
    current_time = datetime(2023, 1, 1, 12, 5) # 4 hours and 5 mins later
    assert should_run_job(db_mock, "job123", "Every 4 Hours", current_time) is True
    
    # Less than 4 hours later
    current_time_early = datetime(2023, 1, 1, 11, 0)
    assert should_run_job(db_mock, "job123", "Every 4 Hours", current_time_early) is False

def test_should_run_job_daily():
    db_mock = MagicMock()
    query_mock = MagicMock()
    run_doc_mock = MagicMock()
    
    # Last run was yesterday
    last_run_time = datetime(2023, 1, 1, 8, 0)
    run_doc_mock.to_dict.return_value = {"created_at": last_run_time}
    query_mock.where.return_value.order_by.return_value.limit.return_value.get.return_value = [run_doc_mock]
    db_mock.collection.return_value = query_mock
    
    current_time = datetime(2023, 1, 2, 8, 5) # 24 hours and 5 mins later
    assert should_run_job(db_mock, "job123", "Daily", current_time) is True
    
    # Less than 24 hours later
    current_time_early = datetime(2023, 1, 1, 20, 0) # 12 hours later
    assert should_run_job(db_mock, "job123", "Daily", current_time_early) is False
