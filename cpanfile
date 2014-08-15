requires 'parent', 0;
requires 'Tickit', '>= 0.46';
requires 'Tickit::Widget', 0;

requires 'Imager', 0;
requires 'Imager::Font', 0;

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
};

