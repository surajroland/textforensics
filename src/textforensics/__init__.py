"""
TextForensics: Neural Text Forensics Platform

A comprehensive platform for text forensics, including style analysis, 
plagiarism detection, and style transfer using unified neural architectures.
"""

__version__ = "0.1.0"

from .models import *
from .pipelines import *
from .utils import *

__all__ = [
    "TextForensicsUnifiedModel",
    "StyleMimic", 
    "AuthorTrace",
    "TrainingPipeline",
    "EvaluationPipeline",
    "InferencePipeline",
]
