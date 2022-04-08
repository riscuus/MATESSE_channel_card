import os
from venv import create


def create_folder(directory):
    os.mkdir(directory)

if __name__ == "__main__":
    create_folder("data\\test_4\\hola")
