import pytest
from handler import handle

def test_handle():
    res = handle("Test")
    assert res == "Hello! You said: Test", "Should be equals"
