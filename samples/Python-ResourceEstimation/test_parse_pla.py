import pytest

from parse_pla import *

class TestMPMCTTally:
    def test_all_max(self):
        expected_num_total_controls = 5
        expected_mpmct_tally = {5 : 6}

        num_total_controls, mpmct_tally = count_mpmcts("test_exorcisms/all_max.exorcised")

        assert num_total_controls == expected_num_total_controls
        assert mpmct_tally == expected_mpmct_tally

    def test_all_min(self):
        expected_num_total_controls = 4
        expected_mpmct_tally = {1 : 4}

        num_total_controls, mpmct_tally = count_mpmcts("test_exorcisms/all_min.exorcised")

        assert num_total_controls == expected_num_total_controls
        assert mpmct_tally == expected_mpmct_tally

    def test_one_each(self):
        expected_num_total_controls = 8
        expected_mpmct_tally = {x : 1 for x in range(1, expected_num_total_controls + 1)}

        num_total_controls, mpmct_tally = count_mpmcts("test_exorcisms/one_each.exorcised")

        assert num_total_controls == expected_num_total_controls
        assert mpmct_tally == expected_mpmct_tally

    def test_random(self):
        expected_num_total_controls = 7
        expected_mpmct_tally = {2 : 3, 3 : 4, 4 : 3, 5 : 1, 6 : 3, 7 : 1}

        num_total_controls, mpmct_tally = count_mpmcts("test_exorcisms/random.exorcised")

        assert num_total_controls == expected_num_total_controls
        assert mpmct_tally == expected_mpmct_tally