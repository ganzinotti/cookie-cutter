import pytest

from project.brain import add_number


def test_add_number():
    result = add_number(2, 3)
    assert 5 == result