return {
    goomba = {
		  { --Walk
        {112+256, 0, 0, false, false};
        {113+256, 8, 0, false, false};
        {114+256, 0, 8, false, false};
        {115+256, 8, 8, false, false};
		  },
		  { --Squished
		    {239+256, 0, 8, false, true};
		    {239+256, 8, 8, true, true};
		  },
    };
    koopa = {
      { --Walk 1
        {165+256, 8, -8, false, false};
        {166+256, 0, 0, false, false};
        {167+256, 8, 0, false, false};
        {168+256, 0, 8, false, false};
        {169+256, 8, 8, false, false};
      },
      { --Walk 2
        {160+256, 8, -8, false, false};
        {161+256, 0, 0, false, false};
        {162+256, 8, 0, false, false};
        {163+256, 0, 8, false, false};
        {164+256, 8, 8, false, false};
      },
      { --Shell 1
        {110+256, 0, 0, false, false};
        {110+256, 8, 0, true, false};
        {111+256, 0, 8, false, false};
        {111+256, 8, 8, true, false};
		  },
      { --Shell 2
        {109+256, 0, 0, false, false};
        {109+256, 8, 0, true, false};
        {111+256, 0, 8, false, false};
        {111+256, 8, 8, true, false};
		  },
    };
}